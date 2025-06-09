// user-server.js
const express = require('express');
const bodyParser = require('body-parser');
const sqlite3 = require('sqlite3').verbose();
const cors = require('cors');
const app = express();
const PORT = 8081;

app.use(cors());
app.use(bodyParser.json());

const db = new sqlite3.Database('wat2watch.db');
db.serialize(() => {
  db.run(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      password TEXT NOT NULL,
      name TEXT,
      subscribed_ott TEXT,
      favorite_genres TEXT
    )
  `);
  db.run(`
    CREATE TABLE IF NOT EXISTS ratings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId TEXT NOT NULL,
      contentId TEXT NOT NULL,
      rating REAL NOT NULL,
      comment TEXT,
      timestamp TEXT,
      FOREIGN KEY (userId) REFERENCES users(id)
    )
  `);
});
// 회원가입
app.post('/register', (req, res) => {
  const id = req.body.id;
  const password = req.body.password;
  const name = req.body.name;
  const subscribedOtt = req.body.subscribedOtt || req.body.subscribed_ott;
  const favoriteGenres = req.body.favoriteGenres || req.body.favorite_genres;

  console.log('REQ BODY (register):', req.body);

  if (!id || !password) return res.status(400).send('Missing id or password');
  db.run(
    `INSERT INTO users (id, password, name, subscribed_ott, favorite_genres)
     VALUES (?, ?, ?, ?, ?)`,
    [
      id,
      password,
      name,
      JSON.stringify(subscribedOtt || []),
      JSON.stringify(favoriteGenres || [])
    ],
    function(err) {
      if (err) {
        if (err.code === 'SQLITE_CONSTRAINT') return res.status(409).send('ID already exists');
        return res.status(500).send('DB Error');
      }
      res.send('User registered!');
    }
  );
});

// 로그인
app.post('/login', (req, res) => {
  const { id, password } = req.body;
  db.get(
    'SELECT * FROM users WHERE id = ? AND password = ?',
    [id, password],
    (err, row) => {
      if (err) return res.status(500).send('DB Error');
      if (row) {
        res.json({
          id: row.id,
          name: row.name,
          subscribedOtt: JSON.parse(row.subscribed_ott || '[]'),
          favoriteGenres: JSON.parse(row.favorite_genres || '[]'),
        });
      } else {
        res.status(401).send('Invalid credentials');
      }
    }
  );
});

// 유저 정보 조회 (optional: 서버간 통신용)
app.get('/user/:userId', (req, res) => {
  const userId = req.params.userId;
  db.get('SELECT * FROM users WHERE id = ?', [userId], (err, row) => {
    if (err) return res.status(500).send('DB Error');
    if (row) {
      res.json({
        id: row.id,
        name: row.name,
        subscribedOtt: JSON.parse(row.subscribed_ott || '[]'),
        favoriteGenres: JSON.parse(row.favorite_genres || '[]'),
      });
    } else {
      res.status(404).send('User not found');
    }
  });
});

app.listen(PORT, () => {
  console.log(`User server running at http://localhost:${PORT}`);
});
