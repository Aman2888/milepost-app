import 'package:flutter/material.dart';
import '../core/site.dart';
import '../core/theme.dart';
import '../core/tool_model.dart';
import '../core/tools_data.dart';
import '../widgets/decor.dart';
import '../widgets/ui.dart';
import 'hero_ticket.dart';
import 'tool_screen.dart';

void _openAbout(BuildContext context) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => const AboutScreen()));

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final calcs = tools.where((t) => !t.isLookup).toList();
    final lookups = tools.where((t) => t.isLookup).toList();
    return Scaffold(
      body: IndexedStack(
        index: tab,
        children: [
          _HomeTab(
              calcs: calcs,
              lookups: lookups,
              onSeeAll: (i) => setState(() => tab = i)),
          _ListTab(title: 'Calculators', items: calcs),
          _ListTab(title: 'Lookups', items: lookups),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF175089),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Colors.white),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate, color: Colors.white),
            label: 'Calculators',
          ),
          NavigationDestination(
            icon: Icon(Icons.manage_search),
            selectedIcon: Icon(Icons.manage_search, color: Colors.white),
            label: 'Lookups',
          ),
        ],
      ),
    );
  }
}

List<Widget> _aboutAction(BuildContext context) => [
      IconButton(
        tooltip: 'About and privacy',
        icon: const Icon(Icons.info_outline),
        onPressed: () => _openAbout(context),
      ),
    ];

class _HomeTab extends StatelessWidget {
  final List<Tool> calcs, lookups;
  final ValueChanged<int> onSeeAll;
  const _HomeTab(
      {required this.calcs, required this.lookups, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final popular = calcs.take(4).toList();
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: const Row(children: [
            MilepostMark(height: 28),
            SizedBox(width: 10),
            Text(siteName, style: TextStyle(fontWeight: FontWeight.w700)),
          ]),
          actions: _aboutAction(context),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                'Know what the drive will cost before you turn the key.',
                style: text.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600, height: 1.25),
              ),
              const SizedBox(height: 8),
              Text(
                '${calcs.length} free calculators and ${lookups.length} vehicle lookups using official NHTSA data. No sign-up.',
                style:
                    text.bodyMedium?.copyWith(color: C.inkSoft, height: 1.45),
              ),
              const SizedBox(height: 20),
              const HeroTicket(),
              _SectionHeader('Popular calculators',
                  action: 'See all', onAction: () => onSeeAll(1)),
              for (final t in popular) _ToolTile(t),
              _SectionHeader('Vehicle lookups',
                  action: 'See all', onAction: () => onSeeAll(2)),
              for (final t in lookups.take(2)) _ToolTile(t),
              const _Footer(),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ListTab extends StatelessWidget {
  final String title;
  final List<Tool> items;
  const _ListTab({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          actions: _aboutAction(context),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          sliver: SliverList(
            delegate:
                SliverChildListDelegate([for (final t in items) _ToolTile(t)]),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title, action;
  final VoidCallback onAction;
  const _SectionHeader(this.title,
      {required this.action, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 0, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          TextButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final Tool tool;
  const _ToolTile(this.tool);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: C.card,
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: ToolIcon(glyph: tool.glyph, tone: tool.tone),
        title: Text(tool.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(tool.short, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => openTool(context, tool),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final small = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: C.inkSoft, height: 1.5);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          4, 28, 4, 24 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calculator results are estimates. Prices, rates and real-world efficiency vary, so treat the answers as a guide, not a quote.',
            style: small,
          ),
          const SizedBox(height: 8),
          Text(
            'Vehicle data comes from the U.S. National Highway Traffic Safety Administration (NHTSA). Milepost is not affiliated with or endorsed by NHTSA.',
            style: small,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _openAbout(context),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text('About and privacy'),
          ),
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: const [
            Text(siteDescription, style: TextStyle(fontSize: 16, height: 1.5)),
            SizedBox(height: 16),
            Panel(
              title: 'Your data',
              child: Text(
                'The calculators run entirely on your phone. Nothing you type into them is sent anywhere.\n\n'
                'The four vehicle lookups send the VIN, or the year, make and model you pick, directly to NHTSA’s free public APIs '
                '(api.nhtsa.gov and vpic.nhtsa.dot.gov) to fetch the results. This app has no accounts and no server of its own.',
                style: TextStyle(height: 1.5),
              ),
            ),
            SizedBox(height: 14),
            Panel(
              title: 'Good to know',
              child: Text(
                'Results are estimates for planning, not professional advice. Recall, rating and complaint data comes from NHTSA and '
                'covers the US market. A recall list does not say whether one particular car has already been repaired.',
                style: TextStyle(height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
