// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_front/otel_front.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_front-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('messages.create records channel + inbox + AI', () async {
    await tracedFront<String>(
      operation: 'conversations.messages.create',
      invoke: () async => const FrontCallResult(
        value: 'ok',
        result: FrontResult(
          channelKind: 'imap',
          status: 'assigned',
          inboxId: 'inb_1',
          teamId: 'tim_1',
          assigneeId: 'tea_1',
          usesAi: true,
          rateLimitRemaining: 95,
          statusCode: 201,
        ),
      ),
    );
    final a = attrsOf(
      spans.findSpanByName('front conversations.messages.create')!,
    );
    expect(a['front.channel.kind'], 'imap');
    expect(a['front.inbox.id'], 'inb_1');
    expect(a['front.assignee.id'], 'tea_1');
    expect(a['front.uses_ai'], true);
    expect(a['front.rate_limit.remaining'], 95);
  });

  test('suppression skips spans', () async {
    await runWithoutFrontInstrumentationAsync(() async {
      await tracedFront<String>(
        operation: 'conversations.list',
        invoke: () async => const FrontCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('front '), isEmpty);
  });
}
