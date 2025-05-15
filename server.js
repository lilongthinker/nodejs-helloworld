// 引入express模块
const express = require('express');
const app = express();
const port = 3000;

// 定义根路由处理函数
app.get('/', (req, res) => {
  res.send('Hello World');
});

// 启动服务器
app.listen(port, () => {
  console.log(`Example app listening at http://localhost:${port}`);
});
