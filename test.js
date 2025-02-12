const fs = require("fs");


const inputFile = fs.readFileSync("img.jpeg");
const compareFile = fs.readFileSync("out-img.txt");

console.log(
  inputFile.toString("base64") == compareFile.toString("utf8")
    ? "Nice! Node implementation agrees on base64 conversion"
    : "WRONG!!!: Node implementation disagrees with result!!!"
);
