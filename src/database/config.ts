// src/database/config.ts
import * as SQLite from 'expo-sqlite';
import * as FileSystem from 'expo-file-system';

const DB_NAME = 'immunova.db';

// Database will be stored in app's documents directory
export const getDatabasePath = async () => {
  const documentDirectory = FileSystem.documentDirectory;
  return `${documentDirectory}SQLite/${DB_NAME}`;
};

export const initDatabase = async () => {
  try {
    // For expo-sqlite v11+ (current version) - Use openDatabaseAsync
    const db = await SQLite.openDatabaseAsync(DB_NAME);
    
    // Run initial schema creation using execAsync
    await db.execAsync(`
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );
      
      CREATE TABLE IF NOT EXISTS vaccines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );
      
      CREATE TABLE IF NOT EXISTS user_vaccines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        vaccine_id INTEGER NOT NULL,
        date_administered DATE,
        notes TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (vaccine_id) REFERENCES vaccines (id)
      );
    `);
    
    console.log('Database initialized successfully');
    return db;
    
  } catch (error) {
    console.error('Error initializing database:', error);
    throw error;
  }
};


