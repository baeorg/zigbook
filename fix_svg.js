const fs = require('fs');

// 创建一个干净的SVG图像，用于替换损坏的数据
const cleanSvg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="800" height="600">
  <defs>
    <style>
      .node { fill: #f0f0f0; stroke: #333; stroke-width: 2px; }
      .edge { stroke: #333; stroke-width: 2px; }
      .label { font-family: Arial, sans-serif; font-size: 14px; }
    </style>
  </defs>
  <g class="label">
    <rect class="node" x="300" y="50" width="200" height="60" rx="5"/>
    <text x="400" y="85" text-anchor="middle" style="font-weight: bold;">std.testing<br/>测试框架模块</text>

    <rect class="node" x="100" y="150" width="150" height="60" rx="5"/>
    <text x="175" y="185" text-anchor="middle">expect()</text>
    <rect class="node" x="100" y="250" width="150" height="60" rx="5"/>
    <text x="175" y="285" text-anchor="middle">expectEqual()</text>
    <rect class="node" x="100" y="350" width="150" height="60" rx="5"/>
    <text x="175" y="385" text-anchor="middle">expectError()</text>
    <rect class="node" x="100" y="450" width="150" height="60" rx="5"/>
    <text x="175" y="485" text-anchor="middle">expectEqualSlices()</text>
    <rect class="node" x="100" y="550" width="150" height="60" rx="5"/>
    <text x="175" y="585" text-anchor="middle">expectEqualStrings()</text>

    <rect class="node" x="300" y="150" width="150" height="60" rx="5"/>
    <text x="375" y="185" text-anchor="middle">allocator</text>
    <rect class="node" x="300" y="250" width="150" height="60" rx="5"/>
    <text x="375" y="285" text-anchor="middle">failing_allocator</text>

    <rect class="node" x="500" y="150" width="150" height="60" rx="5"/>
    <text x="575" y="185" text-anchor="middle">random_seed</text>
    <rect class="node" x="500" y="250" width="150" height="60" rx="5"/>
    <text x="575" y="285" text-anchor="middle">tmpDir()</text>
    <rect class="node" x="500" y="350" width="150" height="60" rx="5"/>
    <text x="575" y="385" text-anchor="middle">log_level</text>

    <line class="edge" x1="300" y1="110" x2="175" y2="150"/>
    <line class="edge" x1="300" y1="110" x2="375" y2="150"/>
    <line class="edge" x1="300" y1="110" x2="575" y2="150"/>
    <line class="edge" x1="300" y1="110" x2="375" y2="150"/>
    <line class="edge" x1="300" y1="110" x2="575" y2="150"/>
    <line class="edge" x1="300" y1="110" x2="575" y2="150"/>
  </g>
</svg>`;

// 将SVG转换为base64编码
const base64Svg = Buffer.from(cleanSvg).toString('base64');

console.log('新的SVG base64数据:');
console.log(base64Svg);

// 验证base64数据
console.log('\n验证base64数据:');
const decodedSvg = Buffer.from(base64Svg, 'base64').toString('utf8');
console.log('解码成功，长度:', decodedSvg.length);

// 检查是否有损坏字符
console.log('\n检查损坏字符:');
let hasCorruptedChars = false;
for (let i = 0; i < decodedSvg.length; i++) {
    const char = decodedSvg[i];
    if (char.charCodeAt(0) > 127 && !/^[\u4e00-\u9fa5]$/.test(char)) {
        console.log(`位置 ${i}: '${char}' (ASCII: ${char.charCodeAt(0)})`);
        hasCorruptedChars = true;
    }
}

if (!hasCorruptedChars) {
    console.log('没有发现损坏字符');
}

// 保存到文件以便后续使用
fs.writeFileSync('clean_svg_base64.txt', base64Svg);
console.log('\n新的base64数据已保存到 clean_svg_base64.txt');