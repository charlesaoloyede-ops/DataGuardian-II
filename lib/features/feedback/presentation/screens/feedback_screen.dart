import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/feedback_category.dart';
import '../../domain/use_cases/submit_feedback_use_case.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  FeedbackCategory _category = FeedbackCategory.suggestion;
  bool _submitting = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await getIt<SubmitFeedbackUseCase>().call(
        message: _messageCtrl.text,
        category: _category,
        email: _emailCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_emailCtrl.text.trim().isEmpty
              ? 'Thanks! Your feedback has been sent.'
              : 'Thanks! We\'ll reply to your email if needed.'),
        ),
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Couldn\'t send feedback. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Send feedback')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Found a bug or have an idea? Tell us — it goes straight to the '
              'team.',
              style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),

            // ── Category ───────────────────────────────────────────────────
            Text('Type',
                style: textTheme.titleSmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: FeedbackCategory.values.map((c) {
                return ChoiceChip(
                  label: Text(c.label),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Message ────────────────────────────────────────────────────
            TextFormField(
              controller: _messageCtrl,
              minLines: 4,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Your message',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().length < 5) {
                  return 'Please add a little more detail';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Optional email ─────────────────────────────────────────────
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                helperText: 'Add it only if you\'d like a reply.',
                prefixIcon: Icon(Icons.mail_outline_rounded),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return null; // optional
                final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t);
                return ok ? null : 'Enter a valid email address';
              },
            ),
            const SizedBox(height: 16),

            Text(
              'To help us investigate, your app version and device model are '
              'attached. We never collect your browsing or which apps you use.',
              style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 28),

            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Send feedback'),
            ),
          ],
        ),
      ),
    );
  }
}
