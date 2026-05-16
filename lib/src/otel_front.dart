// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_front_suppression.dart';

const _tracerName = 'dartastic_otel_libs_front';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class FrontResult {
  const FrontResult({
    this.itemCount,
    this.channelKind,
    this.status,
    this.inboxId,
    this.teamId,
    this.assigneeId,
    this.usesAi,
    this.rateLimitRemaining,
    this.requestId,
    this.statusCode,
  });

  /// `_results.length`.
  final int? itemCount;

  /// Channel kind: `imap` / `smtp` / `twilio` / `truly` / `intercom` /
  /// `front_chat` / `custom` / `front`. Different channels have very
  /// different webhook latencies + retry semantics.
  final String? channelKind;

  /// `assigned` / `unassigned` / `archived` / `deleted` / `spam` /
  /// `open` / `reminder`.
  final String? status;

  /// Front inbox id.
  final String? inboxId;

  /// Owning team id.
  final String? teamId;

  /// Currently-assigned teammate id.
  final String? assigneeId;

  /// Whether Front AI was used in this call (summary/draft/labels).
  final bool? usesAi;

  /// `X-Rate-Limit-Remaining` per-minute bucket.
  final int? rateLimitRemaining;

  /// `X-Request-Id`.
  final String? requestId;

  final int? statusCode;
}

class FrontCallResult<T> {
  const FrontCallResult({required this.value, this.result});
  final T value;
  final FrontResult? result;
}

/// Wraps a Front Core API call in a CLIENT span. [operation] is one of
/// `conversations.list`, `conversations.get`, `conversations.update`,
/// `conversations.messages.list`, `conversations.messages.create`,
/// `conversations.comments.create`, `conversations.assign`,
/// `conversations.archive`, `conversations.add_tag`, `inboxes.list`,
/// `inboxes.get`, `teams.list`, `teammates.list`, `channels.list`,
/// `channels.import_message`, `rules.list`, `rules.create`,
/// `webhooks.create`, `ai.summarize`, `ai.draft`.
Future<T> tracedFront<T>({
  required String operation,
  required Future<FrontCallResult<T>> Function() invoke,
}) async {
  if (frontInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'front',
    'rpc.method': operation,
    'front.operation': operation,
  };

  final span = _tracer().startSpan(
    'front $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.itemCount != null) {
        extras.add(OTel.attributeInt(
          'front.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.channelKind != null) {
        extras.add(OTel.attributeString(
          'front.channel.kind',
          r.result!.channelKind!,
        ));
      }
      if (r.result!.status != null) {
        extras.add(OTel.attributeString(
          'front.conversation.status',
          r.result!.status!,
        ));
      }
      if (r.result!.inboxId != null) {
        extras.add(OTel.attributeString(
          'front.inbox.id',
          r.result!.inboxId!,
        ));
      }
      if (r.result!.teamId != null) {
        extras.add(OTel.attributeString(
          'front.team.id',
          r.result!.teamId!,
        ));
      }
      if (r.result!.assigneeId != null) {
        extras.add(OTel.attributeString(
          'front.assignee.id',
          r.result!.assigneeId!,
        ));
      }
      if (r.result!.usesAi != null) {
        extras.add(OTel.attributeBool(
          'front.uses_ai',
          r.result!.usesAi!,
        ));
      }
      if (r.result!.rateLimitRemaining != null) {
        extras.add(OTel.attributeInt(
          'front.rate_limit.remaining',
          r.result!.rateLimitRemaining!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTel.attributeString(
          'front.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Front HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
