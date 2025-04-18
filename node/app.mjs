import express from "express";

const app = express();

app.get('/', (req, res) => {
  res.send('<h1>Hi there, Javier</h1>');
});

app.listen(80);
