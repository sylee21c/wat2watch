// rating-server.js
const express = require('express');
const bodyParser = require('body-parser');
const sqlite3 = require('sqlite3').verbose();
const cors = require('cors');
const app = express();
const PORT = 8082;

app.use(cors());
app.use(bodyParser.json());

const db = new sqlite3.Database('wat2watch.db');

// 별점 등록/수정
app.post('/ratings', (req, res) => {
  const userId = req.body.userId || req.body.user_id;
  const contentId = req.body.contentId || req.body.content_id;
  const rating = Number(req.body.rating);
  const comment = req.body.comment;

  console.log('userId:', userId, '| contentId:', contentId, '| rating:', rating, '| comment:', comment);

  if (!userId || !contentId || rating == null) {
    console.error('[400] Missing parameter(s):', req.body);
    return res.status(400).send('Missing parameter(s)');
  }

  db.get(
    'SELECT id FROM ratings WHERE userId = ? AND contentId = ?',
    [userId, contentId],
    (err, row) => {
      if (err) {
        console.error('DB SELECT error:', err);
        return res.status(500).send('DB Error');
      }
      const timestamp = new Date().toISOString();
      if (row) {
        db.run(
          'UPDATE ratings SET rating = ?, comment = ?, timestamp = ? WHERE id = ?',
          [rating, comment || '', timestamp, row.id],
          function(err2) {
            if (err2) {
              console.error('DB UPDATE error:', err2);
              return res.status(500).send('DB Error');
            }
            console.log('[200] Rating updated!');
            res.send('Rating updated!');
          }
        );
      } else {
        db.run(
          'INSERT INTO ratings (userId, contentId, rating, comment, timestamp) VALUES (?, ?, ?, ?, ?)',
          [userId, contentId, rating, comment || '', timestamp],
          function(err2) {
            if (err2) {
              console.error('DB INSERT error:', err2);
              return res.status(500).send('DB Error');
            }
            console.log('[200] Rating submitted!');
            res.send('Rating submitted!');
          }
        );
      }
    }
  );
});

// 내 별점 목록 조회
app.get('/user/:userId/ratings', (req, res) => {
  const userId = req.params.userId;
  db.all('SELECT * FROM ratings WHERE userId = ?', [userId], (err, rows) => {
    if (err) return res.status(500).send('DB Error');
    res.json(rows);
  });
});

// 특정 영화에 대한 내 별점 조회
app.get('/ratings/:userId/:contentId', (req, res) => {
  const { userId, contentId } = req.params;
  db.get(
    'SELECT * FROM ratings WHERE userId = ? AND contentId = ?',
    [userId, contentId],
    (err, row) => {
      if (err) return res.status(500).send('DB Error');
      if (row) res.json(row);
      else res.status(404).send('Not rated');
    }
  );
});

app.listen(PORT, () => {
  console.log(`Rating server running at http://localhost:${PORT}`);
});
