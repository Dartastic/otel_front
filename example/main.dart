// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_front/otel_front.dart';

/// Traces Front Core calls with OpenTelemetry.
///
/// `otel_front` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Front Core call in
/// [tracedFront]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'front-example');

  // Wraps a Front Core API call in a CLIENT span.
  final frontId = await tracedFront<String>(
    operation: 'conversations.messages.create',
    invoke: () async {
      // Make the Front Core call here, then report what it returned.
      const id = 'front_8f3a2c';
      return const FrontCallResult(
          value: id,
          result: FrontResult(
              itemCount: 3,
              channelKind: 'imap',
              status: 'assigned',
              inboxId: 'inbox_8f3a2c',
              teamId: 'team_8f3a2c',
              assigneeId: 'assignee_8f3a2c',
              usesAi: true,
              rateLimitRemaining: 25,
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedFront conversations.messages.create returned $frontId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutFrontInstrumentationAsync.
  await runWithoutFrontInstrumentationAsync(
    () => tracedFront<String>(
      operation: 'conversations.messages.create',
      invoke: () async {
        const id = 'front_8f3a2c';
        return const FrontCallResult(
            value: id,
            result: FrontResult(
                itemCount: 3,
                channelKind: 'imap',
                status: 'assigned',
                inboxId: 'inbox_8f3a2c',
                teamId: 'team_8f3a2c',
                assigneeId: 'assignee_8f3a2c',
                usesAi: true,
                rateLimitRemaining: 25,
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
