import * as SQLite from 'expo-sqlite';
import { initDatabase } from './config';

class Database {
  private static instance: Database;
  private db: SQLite.WebSQLDatabase | null = null;

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

  async executeQuery<T>(
    query: string,
    params: any[] = []
  ): Promise<T[]> {
    const db = await this.getConnection();
    return new Promise((resolve, reject) => {
      db.transaction(tx => {
        tx.executeSql(
          query,
          params,
          (_, result) => resolve(result.rows._array as T[]),
          (_, error) => {
            reject(error);
            return false;
          }
        );
      });
    });
  }
}

export const db = Database.getInstance();
