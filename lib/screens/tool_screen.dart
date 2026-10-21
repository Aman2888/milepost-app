import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/tool_model.dart';
import '../widgets/decor.dart';
import '../widgets/ui.dart';
import 'registry.dart';

Future<void> openTool(BuildContext context, Tool tool) {
  return Navigator.of(context).push(MaterialPageRoute(builder: (_) => ToolScreen(tool: tool)));
}

class ToolScreen extends StatelessWidget {
  final Tool tool;
  const ToolScreen({super.key, required this.tool});

  @override
  Widget build(BuildContext context) {
    final builder = toolBuilders[tool.slug];
    return Scaffold(
      appBar: AppBar(title: Text(tool.name)),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
                children: [
                  FadeSlide(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ToolIcon(glyph: tool.glyph, tone: tool.tone, size: 48),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(tool.short, style: const TextStyle(fontSize: 16, color: C.inkSoft, height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  FadeSlide(
                    delay: const Duration(milliseconds: 120),
                    child: builder != null ? builder() : const Text('This tool is not available yet.'),
                  ),
                  const SizedBox(height: 12),
                  FadeSlide(
                    delay: const Duration(milliseconds: 240),
                    child: Panel(
                      title: tool.isLookup ? 'Where the data comes from' : 'How it works',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tool.formula, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4)),
                          if (tool.example != null) ...[
                            const SizedBox(height: 10),
                            Text('Example: ${tool.example}', style: const TextStyle(color: C.inkSoft, height: 1.4)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeSlide(
                    delay: const Duration(milliseconds: 320),
                    child: Panel(
                      title: 'Tips',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final t in tool.tips)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 7, right: 10),
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(color: C.sign, shape: BoxShape.circle),
                                  ),
                                  Expanded(child: Text(t, style: const TextStyle(height: 1.45))),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
