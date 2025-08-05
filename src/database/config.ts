import * as SQLite from 'expo-sqlite';
import * as FileSystem from 'expo-file-system';
import { Asset } from 'expo-asset';

const DB_NAME = 'immunova.db';
const MIGRATIONS_PATH = '../db/migrations/sqlite';

// Database will be stored in app's documents directory
export const getDatabasePath = async () => {
  const documentDirectory = FileSystem.documentDirectory;
  return `${documentDirectory}SQLite/${DB_NAME}`;
};

export const initDatabase = async () => {
  const dbPath = await getDatabasePath();
  
  // Ensure SQLite directory exists
  const dbDirectory = `${FileSystem.documentDirectory}SQLite`;
  const { exists } = await FileSystem.getInfoAsync(dbDirectory);
  if (!exists) {
    await FileSystem.makeDirectoryAsync(dbDirectory, { intermediates: true });
  }

  // Check if database exists
  const dbExists = await FileSystem.getInfoAsync(dbPath);
  if (!dbExists.exists) {
    // Copy initial database from assets if it doesn't exist
    try {
      const migrationFile = require.resolve(MIGRATIONS_PATH + '/001_initial_schema.sql');
      const sqlContent = await FileSystem.readAsStringAsync(migrationFile);
      
      const db = SQLite.openDatabase(DB_NAME);
      await new Promise((resolve, reject) => {
        db.transaction(tx => {
          tx.executeSql(sqlContent, [], 
            () => resolve(true),
            (_, error) => reject(error)
          );
        });
      });
      
      console.log('Database initialized successfully');
    } catch (error) {
      console.error('Error initializing database:', error);
      throw error;
    }
  }

  return SQLite.openDatabase(DB_NAME);
};
