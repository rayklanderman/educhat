-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create users table
CREATE TABLE users (
    user_id UUID REFERENCES auth.users NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_online BOOLEAN DEFAULT FALSE,
    is_typing JSONB DEFAULT '{}' -- Stores chat_id -> timestamp pairs
);

-- Create chats table
CREATE TABLE chats (
    chat_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    type TEXT NOT NULL CHECK (type IN ('1:1', 'group')),
    created_by UUID REFERENCES users(user_id),
    name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create messages table
CREATE TABLE messages (
    message_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    chat_id UUID REFERENCES chats(chat_id) ON DELETE CASCADE,
    sender_id UUID REFERENCES users(user_id),
    content JSONB NOT NULL, -- Stores text content or metadata for multimedia
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create files table
CREATE TABLE files (
    file_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    uploaded_by UUID REFERENCES users(user_id),
    file_url TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_type TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create chat_participants table for managing group chats
CREATE TABLE chat_participants (
    chat_id UUID REFERENCES chats(chat_id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (chat_id, user_id)
);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE files ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_participants ENABLE ROW LEVEL SECURITY;

-- Create policies for users
CREATE POLICY "Users can view their own profile"
ON users FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can view chat participants' profiles"
ON users FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM chat_participants cp
        WHERE cp.user_id = users.user_id
        AND EXISTS (
            SELECT 1 FROM chat_participants
            WHERE chat_id = cp.chat_id
            AND user_id = auth.uid()
        )
    )
);

CREATE POLICY "Users can update their own profile"
ON users FOR UPDATE
USING (auth.uid() = user_id);

-- Create policies for chats
CREATE POLICY "Users can view their chats"
ON chats FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM chat_participants
        WHERE chat_id = chats.chat_id
        AND user_id = auth.uid()
    )
);

CREATE POLICY "Users can create chats"
ON chats FOR INSERT
WITH CHECK (auth.uid() = created_by);

-- Create policies for messages
CREATE POLICY "Users can view messages in their chats"
ON messages FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM chat_participants
        WHERE chat_id = messages.chat_id
        AND user_id = auth.uid()
    )
);

CREATE POLICY "Users can send messages to their chats"
ON messages FOR INSERT
WITH CHECK (
    sender_id = auth.uid() AND
    EXISTS (
        SELECT 1 FROM chat_participants
        WHERE chat_id = messages.chat_id
        AND user_id = auth.uid()
    )
);

-- Create policies for files
CREATE POLICY "Users can view files in their chats"
ON files FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM messages m
        JOIN chat_participants cp ON cp.chat_id = m.chat_id
        WHERE m.content->>'file_id' = files.file_id::text
        AND cp.user_id = auth.uid()
    )
);

CREATE POLICY "Users can upload files"
ON files FOR INSERT
WITH CHECK (uploaded_by = auth.uid());

-- Create functions for presence
CREATE OR REPLACE FUNCTION update_user_presence() 
RETURNS TRIGGER AS $$
BEGIN
  UPDATE users
  SET last_seen = NOW(),
      is_online = true
  WHERE user_id = auth.uid();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to update presence on message send
CREATE TRIGGER update_presence_on_message
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION update_user_presence();

-- Function to update typing status
CREATE OR REPLACE FUNCTION update_typing_status(chat_id UUID, is_typing BOOLEAN)
RETURNS void AS $$
BEGIN
  UPDATE users
  SET is_typing = 
    CASE 
      WHEN is_typing THEN 
        jsonb_set(
          COALESCE(is_typing, '{}'::jsonb),
          array[chat_id::text],
          to_jsonb(EXTRACT(EPOCH FROM NOW()))
        )
      ELSE 
        is_typing - chat_id::text
    END
  WHERE user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to cleanup offline users
CREATE OR REPLACE FUNCTION cleanup_offline_users() 
RETURNS void AS $$
BEGIN
  UPDATE users
  SET is_online = false,
      is_typing = '{}'::jsonb
  WHERE last_seen < NOW() - INTERVAL '5 minutes';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE chats, messages, chat_participants;

-- Create storage bucket for files
INSERT INTO storage.buckets (id, name, public)
VALUES ('chat-files', 'Chat Files', false);

-- Storage policies
CREATE POLICY "Authenticated users can upload files"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'chat-files' AND auth.role() = 'authenticated');

CREATE POLICY "Users can access files from their chats"
ON storage.objects FOR SELECT TO authenticated
USING (
    bucket_id = 'chat-files' AND
    EXISTS (
        SELECT 1 FROM files f
        JOIN messages m ON m.content->>'file_id' = f.file_id::text
        JOIN chat_participants cp ON cp.chat_id = m.chat_id
        WHERE f.file_url = storage.objects.name
        AND cp.user_id = auth.uid()
    )
);
