import 'dart:math' as math;
import 'package:clustter_update/clustter_update.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'monitor.dart';
import 'usage.dart';

const jade = Color(0xFF247D70);
const lilac = Color(0xFF7865B0);
const amber = Color(0xFFAB6828);

Color tone(BuildContext context, Color color) =>
    Theme.of(context).brightness == Brightness.dark
    ? Color.lerp(color, Colors.white, .45)!
    : color;

class ThermoApp extends StatelessWidget {
  final Monitor monitor;
  final bool updates;
  const ThermoApp({super.key, required this.monitor, this.updates = true});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: monitor,
    builder: (context, _) {
      final dark = monitor.dark;
      final surface = dark ? const Color(0xFF242D34) : const Color(0xFFE9EFF2);
      return MaterialApp(
        title: 'Thermo · Codex',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: dark ? Brightness.dark : Brightness.light,
          fontFamily: 'Segoe UI',
          scaffoldBackgroundColor: surface,
          colorScheme: ColorScheme.fromSeed(
            seedColor: jade,
            brightness: dark ? Brightness.dark : Brightness.light,
            surface: surface,
          ),
          tooltipTheme: const TooltipThemeData(
            waitDuration: Duration(milliseconds: 350),
          ),
        ),
        builder: updates
            ? (context, child) => ClustterUpdate(
                appId: 'thermo',
                appName: 'Thermo',
                child: child!,
              )
            : null,
        home: Dashboard(monitor: monitor),
      );
    },
  );
}

class Soft extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? tint;
  const Soft({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 26,
    this.tint,
  });
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = Theme.of(context).colorScheme.surface;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tint == null
            ? base
            : Color.alphaBlend(
                tint!.withValues(alpha: dark ? .12 : .035),
                base,
              ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: .045)
              : Colors.white.withValues(alpha: .65),
        ),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black.withValues(alpha: .26)
                : const Color(0xFFBAC7CE).withValues(alpha: .55),
            blurRadius: 22,
            offset: const Offset(8, 8),
          ),
          BoxShadow(
            color: dark
                ? Colors.white.withValues(alpha: .025)
                : Colors.white.withValues(alpha: .95),
            blurRadius: 20,
            offset: const Offset(-8, -8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class Dashboard extends StatelessWidget {
  final Monitor monitor;
  const Dashboard({super.key, required this.monitor});
  Text label(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.9,
    ),
  );

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.f5): () =>
          monitor.refresh(forceActivity: true),
      const SingleActivator(LogicalKeyboardKey.keyM, control: true): () =>
          monitor.toggleCompact(),
      const SingleActivator(LogicalKeyboardKey.keyP, control: true): () =>
          monitor.togglePin(),
    },
    child: Focus(
      autofocus: true,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (monitor.compact) return _compact(context);
              final narrow = constraints.maxWidth < 790;
              return SingleChildScrollView(
                padding: EdgeInsets.all(narrow ? 20 : 34),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1220),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _header(context),
                        const SizedBox(height: 28),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  label('SEU CODEx, EM PERSPECTIVA'),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Seu ritmo, à vista.',
                                    style: TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Um olhar tranquilo sobre o que você ainda pode criar.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!narrow) _status(context),
                          ],
                        ),
                        const SizedBox(height: 26),
                        if (monitor.limitsError != null)
                          _notice(context, monitor.limitsError!),
                        if (narrow) ...[
                          _hero(context),
                          const SizedBox(height: 24),
                          _quotas(context),
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: _hero(context)),
                              const SizedBox(width: 26),
                              Expanded(flex: 6, child: _quotas(context)),
                            ],
                          ),
                        const SizedBox(height: 26),
                        LayoutBuilder(
                          builder: (context, c) {
                            final width =
                                (c.maxWidth - (c.maxWidth < 680 ? 16 : 48)) /
                                (c.maxWidth < 680 ? 2 : 4);
                            return Wrap(
                              spacing: 16,
                              runSpacing: 18,
                              children: [
                                SizedBox(
                                  width: width,
                                  child: _metric(
                                    context,
                                    'Tokens hoje',
                                    pretty(monitor.activity?.day(monitor.now)),
                                    'Histórico da conta¹',
                                    Icons.token_outlined,
                                    jade,
                                    monitor.activity?.day(monitor.now),
                                  ),
                                ),
                                SizedBox(
                                  width: width,
                                  child: _metric(
                                    context,
                                    'Últimos 7 dias',
                                    pretty(monitor.activity?.week(monitor.now)),
                                    'Datas do histórico¹',
                                    Icons.date_range_outlined,
                                    lilac,
                                    monitor.activity?.week(monitor.now),
                                  ),
                                ),
                                SizedBox(
                                  width: width,
                                  child: _metric(
                                    context,
                                    'Tokens / minuto',
                                    pretty(monitor.tokensPerMinute),
                                    'Neste PC · últimos 60 s',
                                    Icons.speed_rounded,
                                    jade,
                                    null,
                                  ),
                                ),
                                SizedBox(
                                  width: width,
                                  child: _metric(
                                    context,
                                    'Tokens restantes',
                                    'Não informado',
                                    'A franquia usa percentuais',
                                    Icons.info_outline_rounded,
                                    amber,
                                    null,
                                    small: true,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 26),
                        if (narrow) ...[
                          _history(context),
                          const SizedBox(height: 24),
                          _local(context),
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 6, child: _history(context)),
                              const SizedBox(width: 26),
                              Expanded(flex: 5, child: _local(context)),
                            ],
                          ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 18,
                          runSpacing: 8,
                          children: [
                            Text(
                              '¹ Tokens podem incluir entrada em cache. Não equivalem à franquia do plano.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              'Conta: 60 s · histórico: 5 min · atividade local: 5 s',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (monitor.activityError != null)
                          Text(
                            monitor.activityError!,
                            style: const TextStyle(fontSize: 12, color: amber),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );

  Widget _header(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 18,
    runSpacing: 12,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Soft(
            padding: const EdgeInsets.all(11),
            radius: 16,
            child: const Icon(Icons.thermostat_rounded, color: jade, size: 25),
          ),
          const SizedBox(width: 14),
          const Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'thermo',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 23,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  'CODEX USAGE MONITOR',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      Wrap(
        children: [
          _action(
            'Atualizar agora · F5',
            Icons.refresh_rounded,
            monitor.loading ? null : () => monitor.refresh(forceActivity: true),
          ),
          _action(
            monitor.paused
                ? 'Retomar atualização automática'
                : 'Pausar atualização automática',
            monitor.paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            monitor.togglePause,
          ),
          _action(
            'Sempre visível · Ctrl+P',
            monitor.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
            () => monitor.togglePin(),
            active: monitor.pinned,
          ),
          _action(
            'Modo compacto · Ctrl+M',
            Icons.picture_in_picture_alt_rounded,
            () => monitor.toggleCompact(),
          ),
          _action(
            monitor.dark ? 'Usar tema claro' : 'Usar tema escuro',
            monitor.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            () => monitor.toggleDark(),
          ),
          _action(
            'Recolher para a bandeja do Windows',
            Icons.keyboard_arrow_down_rounded,
            () => windowChannel.invokeMethod('tray'),
          ),
          _action(
            'Sobre os dados',
            Icons.info_outline_rounded,
            () => _about(context),
          ),
        ],
      ),
    ],
  );
  Widget _action(
    String tooltip,
    IconData icon,
    VoidCallback? callback, {
    bool active = false,
  }) => IconButton(
    tooltip: tooltip,
    onPressed: callback,
    icon: Icon(icon, size: 19, color: active ? jade : null),
    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
  );

  Widget _status(BuildContext context) {
    final text = monitor.paused
        ? 'Atualização pausada'
        : monitor.loading
        ? 'Consultando Codex…'
        : monitor.stale
        ? 'Leitura desatualizada'
        : 'Conectado ao Codex';
    final color = tone(context, monitor.paused || monitor.stale ? amber : jade);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .085),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            monitor.loading ? Icons.sync_rounded : Icons.circle,
            size: monitor.loading ? 14 : 7,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _notice(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: amber, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
          TextButton(
            onPressed: monitor.loading
                ? null
                : () => monitor.refresh(forceActivity: true),
            child: const Text('Tentar de novo'),
          ),
        ],
      ),
    ),
  );

  Widget _hero(BuildContext context) {
    final w = monitor.limiting;
    final remaining = w?.remaining;
    final color = tone(
      context,
      remaining == null || remaining > 30
          ? jade
          : remaining > 10
          ? amber
          : const Color(0xFFC24C53),
    );
    return Soft(
      tint: jade,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: label('Reserva disponível')),
              Icon(Icons.spa_outlined, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 142,
                height: 253,
                child: Thermometer(value: remaining, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      label: remaining == null
                          ? 'Limite disponível não informado'
                          : '${remaining.round()} por cento restantes',
                      child: Text(
                        remaining == null ? '—' : '${remaining.round()}%',
                        style: const TextStyle(
                          fontSize: 58,
                          height: 1.05,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      'para continuar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      w?.label ?? 'Aguardando leitura',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      remaining == null
                          ? 'Conecte sua conta no Codex.'
                          : remaining > 30
                          ? 'Espaço para novas ideias.'
                          : remaining > 10
                          ? 'Vale acompanhar o ritmo.'
                          : 'Sua reserva está baixa.',
                      style: TextStyle(color: color, fontSize: 12, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'O termômetro acompanha a janela com menor saldo.',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quotas(BuildContext context) => Soft(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: label('Janelas da conta')),
            if (monitor.selected?.plan != null)
              Text(
                monitor.selected!.plan!.toUpperCase(),
                style: TextStyle(
                  color: tone(context, lilac),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
          ],
        ),
        if (monitor.buckets.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: DropdownButton<String>(
              isExpanded: true,
              value: monitor.selected!.id,
              items: monitor.buckets
                  .map(
                    (b) => DropdownMenuItem(value: b.id, child: Text(b.label)),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) monitor.select(v);
              },
            ),
          ),
        const SizedBox(height: 21),
        if (monitor.selected == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'As janelas disponíveis aparecerão aqui.\nNenhum limite será presumido.',
              style: TextStyle(fontSize: 13, height: 1.8),
            ),
          ),
        for (final (i, w)
            in (monitor.selected?.windows ?? <QuotaWindow>[]).indexed) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Divider(height: 1),
            ),
          Row(
            children: [
              Icon(
                w.minutes == 10080
                    ? Icons.calendar_month_outlined
                    : Icons.schedule_rounded,
                color: tone(context, i == 0 ? jade : lilac),
                size: 18,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  w.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                w.expired(monitor.now)
                    ? 'A confirmar'
                    : '${w.remaining.round()}% livres',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: tone(context, i == 0 ? jade : lilac),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: w.expired(monitor.now) ? null : w.remaining / 100,
              minHeight: 9,
              color: tone(context, i == 0 ? jade : lilac),
              backgroundColor: (i == 0 ? jade : lilac).withValues(alpha: .1),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 18,
            runSpacing: 4,
            children: [
              Text(
                '${w.used.round()}% utilizados',
                style: const TextStyle(fontSize: 10),
              ),
              Tooltip(
                message:
                    w.resetsAt?.toLocal().toString() ??
                    'Sem previsão informada',
                child: Text(
                  countdown(w.resetsAt, monitor.now),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 22),
        Text(
          monitor.limitsAt == null
              ? 'Aguardando primeira consulta'
              : 'Leitura ${_time(monitor.limitsAt!)} · horário local',
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );

  Widget _metric(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    int? number, {
    bool small = false,
  }) => Soft(
    padding: const EdgeInsets.all(20),
    radius: 22,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: tone(context, color)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 17),
        Tooltip(
          message: number == null ? value : '${exact(number)} tokens',
          child: Text(
            value,
            style: TextStyle(
              fontSize: small ? 17 : 27,
              fontWeight: FontWeight.w700,
              letterSpacing: -.7,
            ),
          ),
        ),
        const SizedBox(height: 9),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );

  Widget _history(BuildContext context) {
    final days = List.generate(
      7,
      (i) => DateTime(
        monitor.now.year,
        monitor.now.month,
        monitor.now.day - 6 + i,
      ),
    );
    final data = days.map((d) => monitor.activity?.daily[dateKey(d)]).toList();
    final max = data.whereType<int>().fold<int>(1, math.max);
    return Soft(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: label('Seu pulso criativo')),
              const Text(
                '7 DIAS',
                style: TextStyle(fontSize: 9, color: lilac, letterSpacing: 1.3),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Atividade de tokens informada pela conta',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 128,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                7,
                (i) => Expanded(
                  child: Tooltip(
                    message:
                        '${dateKey(days[i])}: ${data[i] == null ? 'sem dado informado' : '${exact(data[i]!)} tokens'}',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          data[i] == null ? '—' : pretty(data[i]),
                          style: const TextStyle(fontSize: 9),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 24,
                          height: data[i] == null
                              ? 3
                              : math.max(4, 78 * data[i]! / max),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: data[i] == null
                                  ? [
                                      Colors.grey.withValues(alpha: .2),
                                      Colors.grey.withValues(alpha: .2),
                                    ]
                                  : i == 6
                                  ? [const Color(0xFF64B4A1), jade]
                                  : [
                                      const Color(0xFFB3A7D5),
                                      lilac.withValues(alpha: .55),
                                    ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          i == 6 ? 'hoje' : '${days[i].day}/${days[i].month}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: i == 6
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 13),
          Text(
            'Datas do servidor · ausências aparecem como “—”.',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _local(BuildContext context) => Soft(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: label('Neste computador')),
            Icon(Icons.computer_outlined, size: 18, color: jade),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Eventos de tokens registrados hoje, em horário local',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        _dataRow(
          'Entrada',
          monitor.local.available ? pretty(monitor.local.input) : '—',
          jade,
        ),
        _dataRow(
          'Da entrada, em cache',
          monitor.local.available ? pretty(monitor.local.cached) : '—',
          lilac,
        ),
        _dataRow(
          'Saída',
          monitor.local.available ? pretty(monitor.local.output) : '—',
          jade,
        ),
        const SizedBox(height: 8),
        Text(
          monitor.localError ??
              (monitor.local.latest == null
                  ? 'Nenhum evento de tokens local disponível hoje.'
                  : 'Último evento ${_time(monitor.local.latest!)} · pode haver atraso.'),
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
  Widget _dataRow(String title, String value, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 9),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 12))),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _compact(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        Row(
          children: [
            const Icon(Icons.thermostat_rounded, color: jade),
            const SizedBox(width: 7),
            const Expanded(
              child: Text(
                'thermo',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
            ),
            _action(
              'Sempre visível · Ctrl+P',
              monitor.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              () => monitor.togglePin(),
              active: monitor.pinned,
            ),
            _action(
              'Expandir painel · Ctrl+M',
              Icons.open_in_full_rounded,
              () => monitor.toggleCompact(),
            ),
            _action(
              'Bandeja do Windows',
              Icons.keyboard_arrow_down_rounded,
              () => windowChannel.invokeMethod('tray'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _status(context),
        const SizedBox(height: 16),
        Soft(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                height: 160,
                child: Thermometer(
                  value: monitor.limiting?.remaining,
                  color: jade,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monitor.limiting == null
                          ? '—'
                          : '${monitor.limiting!.remaining.round()}%',
                      style: const TextStyle(
                        fontSize: 43,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -2,
                      ),
                    ),
                    const Text('restantes', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 13),
                    Text(
                      '${pretty(monitor.tokensPerMinute)} tokens/min',
                      style: TextStyle(
                        fontSize: 11,
                        color: tone(context, jade),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        for (final w in monitor.selected?.windows ?? <QuotaWindow>[])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(w.label, style: const TextStyle(fontSize: 11)),
                ),
                Text(
                  w.expired(monitor.now)
                      ? 'A confirmar'
                      : '${w.remaining.round()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        if (monitor.limitsError != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              monitor.limitsError!,
              style: const TextStyle(fontSize: 11, color: amber),
            ),
          ),
        TextButton.icon(
          onPressed: monitor.loading
              ? null
              : () => monitor.refresh(forceActivity: true),
          icon: const Icon(Icons.refresh_rounded, size: 17),
          label: const Text('Atualizar', style: TextStyle(fontSize: 11)),
        ),
      ],
    ),
  );
  String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
  void _about(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Um termômetro honesto.'),
      content: const SingleChildScrollView(
        child: SizedBox(
          width: 470,
          child: Text(
            'Thermo 0.1.0 · Monitor independente para Windows.\n\nOs percentuais e renovações vêm de account/rateLimits/read. O termômetro usa a janela válida com menor saldo; isso não combina ou soma franquias.\n\nO histórico vem de account/usage/read, com datas definidas pelo servidor e possível atraso. Os tokens podem incluir entrada em cache e não são uma medida de cobrança ou uma conversão da franquia do plano.\n\nTokens por minuto e detalhes locais vêm somente dos eventos token_count em CODEX_HOME/sessions neste PC. Contagens locais podem ser incompletas e não incluem outros computadores. A taxa considera até 60 segundos de observação com o monitor aberto.\n\nA OpenAI não informa uma franquia fixa de tokens neste contrato. Por isso, tokens restantes aparecem como “Não informado”.\n\nO app não cria conversas ou gera respostas. Não lê auth.json, não salva histórico de uso nem exporta conversas. Usa o login gerenciado pelo Codex instalado. Preferências visuais ficam neste PC.\n\nF5: atualizar · Ctrl+M: compacto · Ctrl+P: sempre visível. O botão de recolher mantém o monitor na bandeja; clique no ícone para voltar. Fechar a janela encerra o app.',
            style: TextStyle(fontSize: 13, height: 1.6),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendi'),
        ),
      ],
    ),
  );
}

class Thermometer extends StatelessWidget {
  final double? value;
  final Color color;
  const Thermometer({super.key, this.value, required this.color});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Termômetro de reserva',
    value: value == null ? 'Sem leitura' : '${value!.round()} por cento',
    child: CustomPaint(
      painter: _ThermometerPainter(
        value,
        color,
        Theme.of(context).brightness == Brightness.dark,
      ),
    ),
  );
}

class _ThermometerPainter extends CustomPainter {
  final double? value;
  final Color color;
  final bool dark;
  _ThermometerPainter(this.value, this.color, this.dark);
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 142, sy = size.height / 253;
    canvas.save();
    canvas.scale(sx, sy);
    final outer = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(46, 8, 42, 187),
          const Radius.circular(21),
        ),
      )
      ..addOval(const Rect.fromLTWH(32, 174, 70, 70));
    canvas.drawShadow(
      outer,
      dark ? Colors.black : const Color(0xFF96A9B2),
      9,
      false,
    );
    canvas.drawPath(
      outer,
      Paint()..color = dark ? const Color(0xFF35424B) : const Color(0xFFF5F9FA),
    );
    final stem = RRect.fromRectAndRadius(
      const Rect.fromLTWH(56, 20, 22, 187),
      const Radius.circular(11),
    );
    canvas.drawRRect(
      stem,
      Paint()..color = dark ? const Color(0xFF1A232B) : const Color(0xFFD2DEE2),
    );
    final fill = value == null ? 0.0 : value!.clamp(0, 100) / 100;
    final rect = Rect.fromLTWH(59, 24 + 172 * (1 - fill), 16, 172 * fill + 14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, Colors.white, .45)!, color],
        ).createShader(rect),
    );
    canvas.drawCircle(
      const Offset(67, 209),
      26,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.4, -.4),
          colors: [Color.lerp(color, Colors.white, .4)!, color],
        ).createShader(const Rect.fromLTWH(41, 183, 52, 52)),
    );
    canvas.drawCircle(
      const Offset(60, 201),
      9,
      Paint()..color = Colors.white.withValues(alpha: .12),
    );
    for (int i = 0; i <= 10; i++) {
      final y = 24.0 + i * 16.5;
      canvas.drawLine(
        Offset(96, y),
        Offset(i % 5 == 0 ? 110 : 104, y),
        Paint()
          ..color = (dark ? Colors.white : const Color(0xFF647984)).withValues(
            alpha: .35,
          )
          ..strokeWidth = 1.4,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ThermometerPainter old) =>
      old.value != value || old.color != color || old.dark != dark;
}
