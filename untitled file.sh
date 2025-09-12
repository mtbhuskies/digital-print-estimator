#!/bin/bash

gsed -i 's/theconst sheetW/const sheetW/' src/App.jsx 2>/dev/null || sed -i '' 's/theconst sheetW/const sheetW/' src/App.jsx
