# 📝 Markdown to Notion Converter

✨ A Dart command-line tool that converts Markdown files to Notion-compatible format. This tool transforms standard Markdown syntax into a format that can be easily copy-pasted into Notion pages.

## 🚀 Features

- 📋 **Headers**: Converts H1-H6 headers (H4-H6 become bold H3)
- 🎨 **Text Formatting**: Bold, italic, strikethrough, and inline code
- 📝 **Lists**: Unordered and ordered lists with proper nesting
- 🔗 **Links**: Markdown links with preserved formatting
- 💻 **Code Blocks**: Fenced code blocks with syntax highlighting preservation
- 📊 **Tables**: Basic table conversion with improved formatting
- 🧹 **Whitespace Cleanup**: Removes excessive blank lines and trailing whitespace

## 🛠️ Installation

Make sure you have Dart SDK installed on your system.

## 📖 Usage

```bash
dart markdown_to_notion.dart <input_file.md> [output_file.txt]
```

### 💡 Examples

Convert a README file:

```bash
dart markdown_to_notion.dart README.md
# Output: README_notion.txt
```

Specify custom output file:

```bash
dart markdown_to_notion.dart document.md notion_output.txt
```

## 🎯 Supported Markdown Features

### 📐 Headers

```markdown
# H1 Header → # H1 Header
## H2 Header → ## H2 Header
### H3 Header → ### H3 Header
#### H4 Header → ### **H4 Header**
```

### ✍️ Text Formatting

```markdown
**bold** → **bold**
*italic* → *italic*
~~strikethrough~~ → ~~strikethrough~~
`inline code` → `inline code`
```

### 📋 Lists

```markdown
- Unordered list → - Unordered list
1. Ordered list → 1. Ordered list
  - Nested items → Proper indentation preserved
```

### 🔗 Links

```markdown
[Text](URL) → [Text](URL)
```

### 💻 Code Blocks

````markdown
```language
code here
```
````

Preserves syntax highlighting information for better readability! 🌈

### 📊 Tables

```markdown
| Header 1 | Header 2 |
| -------- | -------- |
| Cell 1   | Cell 2   |
```

Converts to Notion-friendly table format with proper alignment and styling! ✨

## 📋 Example

**Input** (`example.md`):

```markdown
# My Project

This is a **sample** project with *various* formatting.

- Task 1
- Task 2
  - Subtask A
  - Subtask B

Check out [Google](https://google.com) for more info.
```

**Output** (`example_notion.txt`):

```plaintext
# My Project

This is a **sample** project with *various* formatting.

- Task 1
- Task 2
  - Subtask A
  - Subtask B

Check out [Google](https://google.com) for more info.
```

## 📁 Files

- 📜 `markdown_to_notion.dart` - Main converter script
- 📄 `example/test_sample.md` - Comprehensive test file with all supported features
- 📋 `example/test_sample_notion.txt` - Expected output showing conversions

## 📝 Notes

- 🎯 The converter optimizes for Notion's specific markdown flavor
- 📐 Headers beyond H3 are converted to bold H3 headers
- 🔸 Unordered lists use dashes (-) for better Notion compatibility
- 📊 Tables are formatted with clear headers and separators
- 🌈 Code blocks preserve language information for syntax highlighting
- 🧹 Excessive whitespace is cleaned up for better readability

## 🤝 Contributing

Feel free to submit issues and pull requests to improve the converter's functionality!

---

💡 **Pro Tip**: Use the comprehensive test file (`example/test_sample.md`) to see all features in action!
