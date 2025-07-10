#!/usr/bin/env dart

import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print(
      'Usage: dart markdown_to_notion.dart <input_file.md> [output_file.txt]',
    );
    print('Example: dart markdown_to_notion.dart README.md notion_output.txt');
    exit(1);
  }

  final inputFile = args[0];
  final outputFile = args.length > 1
      ? args[1]
      : '${inputFile.replaceAll('.md', '')}_notion.txt';

  try {
    final content = File(inputFile).readAsStringSync();
    final convertedContent = convertMarkdownToNotion(content);

    File(outputFile).writeAsStringSync(convertedContent);
    print('✅ Successfully converted $inputFile to $outputFile');
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}

String convertMarkdownToNotion(String markdown) {
  var content = markdown;

  // Convert headers
  content = convertHeaders(content);

  // Convert bold and italic text
  content = convertTextFormatting(content);

  // Convert lists
  content = convertLists(content);

  // Convert links
  content = convertLinks(content);

  // Convert code blocks
  content = convertCodeBlocks(content);

  // Convert inline code
  content = convertInlineCode(content);

  // Convert tables (basic support)
  content = convertTables(content);

  // Clean up extra whitespace
  content = cleanupWhitespace(content);

  return content;
}

String convertHeaders(String content) {
  // Convert markdown headers to Notion format
  content = content.replaceAllMapped(
    RegExp(r'^(#{1,6})\s+(.+)$', multiLine: true),
    (match) {
      final level = match.group(1)!.length;
      final text = match.group(2)!;

      // Notion supports up to 3 header levels
      if (level <= 3) {
        return '${'#' * level} $text';
      } else {
        // Convert h4-h6 to h3 with emphasis
        return '### **$text**';
      }
    },
  );

  return content;
}

String convertTextFormatting(String content) {
  // Convert bold text (**text** or __text__)
  content = content.replaceAllMapped(
    RegExp(r'\*\*([^*]+)\*\*'),
    (match) => '**${match.group(1)}**',
  );

  content = content.replaceAllMapped(
    RegExp(r'__([^_]+)__'),
    (match) => '**${match.group(1)}**',
  );

  // Convert italic text (*text* or _text_)
  content = content.replaceAllMapped(
    RegExp(r'(?<!\*)\*([^*]+)\*(?!\*)'),
    (match) => '*${match.group(1)}*',
  );

  content = content.replaceAllMapped(
    RegExp(r'(?<!_)_([^_]+)_(?!_)'),
    (match) => '*${match.group(1)}*',
  );

  // Convert strikethrough - Notion uses double tildes
  content = content.replaceAllMapped(
    RegExp(r'~~([^~]+)~~'),
    (match) => '~~${match.group(1)}~~',
  );

  return content;
}

String convertLists(String content) {
  final lines = content.split('\n');
  final result = <String>[];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];

    // Convert unordered lists - Notion works better with dashes
    if (line.trim().startsWith('- ') ||
        line.trim().startsWith('* ') ||
        line.trim().startsWith('+ ')) {
      final indent = line.indexOf(line.trim());
      final text = line.trim().substring(2);
      result.add('${' ' * indent}- $text');
    }
    // Convert ordered lists
    else if (RegExp(r'^\s*\d+\.\s+').hasMatch(line)) {
      final match = RegExp(r'^(\s*)(\d+)\.\s+(.+)$').firstMatch(line);
      if (match != null) {
        final indent = match.group(1)!;
        final number = match.group(2)!;
        final text = match.group(3)!;
        result.add('$indent$number. $text');
      } else {
        result.add(line);
      }
    } else {
      result.add(line);
    }
  }

  return result.join('\n');
}

String convertLinks(String content) {
  // Convert markdown links [text](url) to Notion format
  content = content.replaceAllMapped(RegExp(r'\[([^\]]+)\]\(([^)]+)\)'), (
    match,
  ) {
    final text = match.group(1)!;
    final url = match.group(2)!;
    return '[$text]($url)';
  });

  return content;
}

String convertCodeBlocks(String content) {
  // Convert fenced code blocks
  content = content.replaceAllMapped(
    RegExp(r'```(\w+)?\n(.*?)\n```', multiLine: true, dotAll: true),
    (match) {
      final language = match.group(1) ?? '';
      final code = match.group(2)!;

      if (language.isNotEmpty) {
        return '```$language\n$code\n```';
      } else {
        return '```\n$code\n```';
      }
    },
  );

  return content;
}

String convertInlineCode(String content) {
  // Convert inline code `code` to Notion format
  content = content.replaceAllMapped(
    RegExp(r'`([^`]+)`'),
    (match) => '`${match.group(1)}`',
  );

  return content;
}

String convertTables(String content) {
  final lines = content.split('\n');
  final result = <String>[];
  var inTable = false;
  var tableRows = <List<String>>[];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];

    // Check if this is a table row
    if (line.trim().startsWith('|') && line.trim().endsWith('|')) {
      if (!inTable) {
        inTable = true;
        tableRows.clear();
      }

      // Skip separator lines (|---|---|)
      if (line.contains('---')) {
        continue;
      }

      // Parse table row
      final cells = line
          .split('|')
          .map((cell) => cell.trim())
          .where((cell) => cell.isNotEmpty)
          .toList();
      tableRows.add(cells);
    } else {
      if (inTable) {
        // Convert accumulated table rows to Notion-friendly format
        result.add(''); // Add empty line before table
        result.addAll(formatTableForNotion(tableRows));
        result.add(''); // Add empty line after table
        inTable = false;
        tableRows.clear();
      }
      result.add(line);
    }
  }

  // Handle table at end of file
  if (inTable && tableRows.isNotEmpty) {
    result.add(''); // Add empty line before table
    result.addAll(formatTableForNotion(tableRows));
  }

  return result.join('\n');
}

List<String> formatTableForNotion(List<List<String>> tableRows) {
  if (tableRows.isEmpty) return [];

  final result = <String>[];

  // Calculate column widths for better formatting
  final columnWidths = <int>[];
  for (var row in tableRows) {
    for (var i = 0; i < row.length; i++) {
      if (i >= columnWidths.length) {
        columnWidths.add(0);
      }
      columnWidths[i] = columnWidths[i] > row[i].length
          ? columnWidths[i]
          : row[i].length;
    }
  }

  // Add header row (first row)
  if (tableRows.isNotEmpty) {
    result.add('**Table:**');
    final headerRow = tableRows[0];
    final formattedHeader = headerRow
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final cell = entry.value;
          return '**${cell.padRight(columnWidths[index])}**';
        })
        .join(' | ');
    result.add(formattedHeader);

    // Add separator line for clarity
    final separator = columnWidths.map((width) => '-' * width).join(' | ');
    result.add(separator);
  }

  // Add data rows
  for (var i = 1; i < tableRows.length; i++) {
    final row = tableRows[i];
    final formattedRow = row
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final cell = entry.value;
          return cell.padRight(columnWidths[index]);
        })
        .join(' | ');
    result.add(formattedRow);
  }

  return result;
}

String cleanupWhitespace(String content) {
  // Remove excessive blank lines
  content = content.replaceAll(RegExp(r'\n{3,}'), '\n\n');

  // Trim trailing whitespace
  content = content.split('\n').map((line) => line.trimRight()).join('\n');

  return content.trim();
}
