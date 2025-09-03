import * as SQLite from 'expo-sqlite';
import { initDatabase } from './config';

class Database {
  private static instance: Database;
  private db: SQLite.SQLiteDatabase | null = null;

  private constructor() {}

  static getInstance(): Database {
    if (!Database.instance) {
      Database.instance = new Database();
    }
    return Database.instance;
  }

  async initialize() {
    if (!this.db) {
      this.db = await initDatabase();
    }
    return this.db;
  }

  async getConnection() {
    if (!this.db) {
      await this.initialize();
    }
    return this.db!;
  }

  // Execute SELECT queries
  async executeQuery<T>(
    query: string,
    params: any[] = []
  ): Promise<T[]> {
    const db = await this.getConnection();
    try {
      const result = await db.getAllAsync(query, params);
      return result as T[];
    } catch (error) {
      console.error('Query execution error:', error);
      throw error;
    }
  }

  // Execute INSERT, UPDATE, DELETE queries
  async executeUpdate(
    query: string,
    params: any[] = []
  ): Promise<SQLite.SQLiteRunResult> {
    const db = await this.getConnection();
    try {
      const result = await db.runAsync(query, params);
      return result;
    } catch (error) {
      console.error('Update execution error:', error);
      throw error;
    }
  }

  // Execute single row query
  async executeQuerySingle<T>(
    query: string,
    params: any[] = []
  ): Promise<T | null> {
    const db = await this.getConnection();
    try {
      const result = await db.getFirstAsync(query, params);
      return result as T | null;
    } catch (error) {
      console.error('Single query execution error:', error);
      throw error;
    }
  }

  async close() {
    if (this.db) {
      await this.db.closeAsync();
      this.db = null;
    }
  }
}

export const db = Database.getInstance();