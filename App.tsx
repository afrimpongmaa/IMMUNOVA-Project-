import { db } from './src/database/db';
import { useEffect } from 'react';

export default function App() {
  useEffect(() => {
    const initDB = async () => {
      try {
        await db.initialize();
        console.log('Database initialized');
      } catch (error) {
        console.error('Failed to initialize database:', error);
      }
    };

    initDB();
  }, []);

  return (
    // ...rest of your App component...
  );
}