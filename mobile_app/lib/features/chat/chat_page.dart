// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:skillbite_mobile/app/localization/app_localizations.dart';
import 'package:skillbite_mobile/app/theme/app_theme_tokens.dart';
import 'package:skillbite_mobile/app/widgets/widgets.dart';
import 'package:skillbite_mobile/core/api/mobile_api_client.dart';
import 'package:skillbite_mobile/core/utils/utils.dart';

String _tr(BuildContext context, String english) => tr(context, english);
Map<String, dynamic> _asMap(Object? value) => asMap(value);
List<dynamic> _asList(Object? value) => asList(value);
String _readString(dynamic source, String key) => readString(source, key);
int _readInt(dynamic source, String key) => readInt(source, key);
String _readPath(dynamic source, List<String> path) => readPath(source, path);
void _showSnack(BuildContext context, String message) =>
    showSnack(context, message);

const _brandTealDark = brandTealDark;
const _line = lineColor;
const _surfaceAlt = surfaceAltColor;

typedef _PageBody = AppPageBody;
typedef _HeaderRow = AppHeaderRow;
typedef _DashboardMetricRow = AppDashboardMetricRow;
typedef _DashboardMetricData = AppDashboardMetricData;
typedef _SectionCard = AppSectionCard;
typedef _RoundIconButton = AppRoundIconButton;
typedef _ManagementRecordCard = AppManagementRecordCard;
typedef _ChatModeChip = AppChatModeChip;
typedef _ConversationRow = AppConversationRow;
typedef _ChatMessageRow = AppChatMessageRow;
typedef _LoadingState = AppLoadingState;
typedef _ErrorState = AppErrorState;

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.api,
    required this.roleBasePath,
    required this.title,
    this.initialShowPrivate = false,
    this.initialSelectedUserId,
  });

  final MobileApiClient api;
  final String roleBasePath;
  final String title;
  final bool initialShowPrivate;
  final int? initialSelectedUserId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late Future<Map<String, dynamic>> teamFuture;
  late Future<Map<String, dynamic>> privateFuture;
  bool showPrivate = false;
  int? selectedUserId;

  @override
  void initState() {
    super.initState();
    showPrivate = widget.initialShowPrivate;
    selectedUserId = widget.initialSelectedUserId;
    _reload();
  }

  void _reload() {
    setState(() {
      teamFuture = widget.api.get('${widget.roleBasePath}/chat/team/');
      final suffix = selectedUserId == null ? '' : '?user_id=$selectedUserId';
      privateFuture =
          widget.api.get('${widget.roleBasePath}/chat/private/$suffix');
    });
  }

  Future<void> _sendTeamMessage() async {
    final controller = TextEditingController();
    final sent = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool saving = false;
        String? errorText;
        return StatefulBuilder(
          builder: (context, setInnerState) {
            Future<void> submit() async {
              setInnerState(() {
                saving = true;
                errorText = null;
              });
              try {
                await widget.api
                    .post('${widget.roleBasePath}/chat/team/send/', {
                  'body': controller.text.trim(),
                });
                if (!mounted) return;
                Navigator.of(context).pop(true);
              } catch (error) {
                setInnerState(() {
                  errorText = error.toString().replaceFirst('Exception: ', '');
                  saving = false;
                });
              }
            }

            return Dialog(
              backgroundColor: const Color(0xFFF3FBF8),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32)),
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.fromLTRB(
                  22,
                  24,
                  22,
                  MediaQuery.of(context).viewInsets.bottom + 22,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tr(context, 'Send Team Message'),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _tr(
                          context,
                          'Share one clear update, question, or instruction with your team.',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF61706C),
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: 22),
                      AppTextField(
                        controller: controller,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        minLines: 5,
                        maxLines: 7,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: _tr(context, 'Message'),
                          alignLabelWithHint: true,
                          hintText: _tr(context, 'Write your message'),
                        ),
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorText!,
                          style: const TextStyle(
                            color: Color(0xFFC54C2B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: saving
                              ? null
                              : () => Navigator.of(context).pop(false),
                          child: Text(_tr(context, 'Cancel')),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: saving ? null : submit,
                          child: Text(
                            saving
                                ? _tr(context, 'Sending...')
                                : _tr(context, 'Send'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    controller.dispose();
    if (sent == true) {
      _showSnack(context, 'Message sent.');
      _reload();
    }
  }

  Future<void> _sendPrivateMessage(List<dynamic> participants) async {
    int? recipientId = selectedUserId ??
        (participants.isEmpty ? null : _readInt(participants.first, 'id'));
    final controller = TextEditingController();
    final focusNode = FocusNode();
    final sent = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool saving = false;
        String? errorText;
        return StatefulBuilder(
          builder: (context, setInnerState) {
            Future<void> submit() async {
              setInnerState(() {
                saving = true;
                errorText = null;
              });
              try {
                await widget.api
                    .post('${widget.roleBasePath}/chat/private/send/', {
                  'recipient_id': recipientId,
                  'body': controller.text.trim(),
                });
                if (!mounted) return;
                Navigator.of(context).pop(true);
              } catch (error) {
                setInnerState(() {
                  errorText = error.toString().replaceFirst('Exception: ', '');
                  saving = false;
                });
              }
            }

            return Dialog(
              backgroundColor: const Color(0xFFF3FBF8),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32)),
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.fromLTRB(
                    22, 24, 22, MediaQuery.of(context).viewInsets.bottom + 22),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tr(context, 'Send Private Message'),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 22),
                      DropdownButtonFormField<int?>(
                        initialValue: recipientId,
                        decoration: InputDecoration(
                            labelText: _tr(context, 'Recipient')),
                        items: [
                          for (final item in participants)
                            DropdownMenuItem<int?>(
                              value: _readInt(item, 'id'),
                              child: Text(_readString(item, 'display_name')),
                            ),
                        ],
                        onChanged: (value) {
                          setInnerState(() {
                            recipientId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                      AppTextField(
                        controller: controller,
                        focusNode: focusNode,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        minLines: 5,
                        maxLines: 7,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: _tr(context, 'Message'),
                          alignLabelWithHint: true,
                          hintText: _tr(context, 'Write your message'),
                        ),
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorText!,
                          style: const TextStyle(
                              color: Color(0xFFC54C2B),
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: saving
                              ? null
                              : () => Navigator.of(context).pop(false),
                          child: Text(_tr(context, 'Cancel')),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: saving ? null : submit,
                          child: Text(saving
                              ? _tr(context, 'Sending...')
                              : _tr(context, 'Send')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    controller.dispose();
    focusNode.dispose();
    if (sent == true) {
      _showSnack(context, 'Private message sent.');
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Future.wait([teamFuture, privateFuture]),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _LoadingState();
        }
        if (snapshot.hasError) {
          return _ErrorState(
            message: snapshot.error.toString().replaceFirst('Exception: ', ''),
          );
        }
        final teamPayload = snapshot.data![0];
        final privatePayload = snapshot.data![1];
        final teamMessages = _asList(teamPayload['messages']);
        final participants = _asList(privatePayload['participants']);
        final conversations = _asList(privatePayload['conversations']);
        final privateMessages = _asList(privatePayload['messages']);
        final selectedUser = _asMap(privatePayload['selected_user']);
        return _PageBody(
          children: [
            _HeaderRow(
              title: widget.title,
              titleColor: _brandTealDark,
              titleFontSize: 26,
              trailing: _RoundIconButton(
                icon: showPrivate ? Icons.edit_outlined : Icons.send_outlined,
                onTap: showPrivate
                    ? () => _sendPrivateMessage(participants)
                    : _sendTeamMessage,
              ),
            ),
            const SizedBox(height: 18),
            _DashboardMetricRow(
              metrics: [
                _DashboardMetricData(
                  'Team feed',
                  '${teamMessages.length}',
                  icon: Icons.campaign_rounded,
                ),
                _DashboardMetricData(
                  'People',
                  '${participants.length}',
                  icon: Icons.people_alt_rounded,
                ),
                _DashboardMetricData(
                  showPrivate ? 'Open thread' : 'Conversations',
                  showPrivate
                      ? '${privateMessages.length}'
                      : '${conversations.length}',
                  icon: showPrivate
                      ? Icons.chat_bubble_rounded
                      : Icons.mark_chat_unread_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _surfaceAlt,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ChatModeChip(
                      label: _tr(context, 'Team'),
                      selected: !showPrivate,
                      onTap: () => setState(() => showPrivate = false),
                    ),
                  ),
                  Expanded(
                    child: _ChatModeChip(
                      label: _tr(context, 'Private'),
                      selected: showPrivate,
                      onTap: () => setState(() => showPrivate = true),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!showPrivate) ...[
              _HeaderRow(
                title: 'Latest team updates',
                trailing: Text(
                  '${teamMessages.length} messages',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF61706C),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 14),
              if (teamMessages.isEmpty)
                _ManagementRecordCard(
                  title: 'Start the conversation',
                  description:
                      'Share important updates, schedule changes, or reminders so the full team stays aligned.',
                  icon: Icons.forum_rounded,
                  secondaryActionLabel: _tr(context, 'Send'),
                  onSecondaryAction: _sendTeamMessage,
                )
              else
                for (final item in teamMessages) ...[
                  _ChatMessageRow(
                    name: _readPath(item, ['sender', 'display_name']),
                    body: _readString(item, 'body'),
                    meta: _readPath(item, ['read_receipt', 'label']),
                    own: false,
                  ),
                  const SizedBox(height: 14),
                ],
            ] else ...[
              _SectionCard(
                title: 'People',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tr(
                        context,
                        'Pick a teammate to review the thread or send a direct message.',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF61706C),
                            height: 1.45,
                          ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int?>(
                      initialValue: selectedUser.isEmpty
                          ? null
                          : _readInt(selectedUser, 'id'),
                      decoration:
                          InputDecoration(labelText: _tr(context, 'Person')),
                      items: [
                        for (final item in participants)
                          DropdownMenuItem<int?>(
                            value: _readInt(item, 'id'),
                            child: Text(_readString(item, 'display_name')),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedUserId = value;
                          final suffix = value == null ? '' : '?user_id=$value';
                          privateFuture = widget.api.get(
                              '${widget.roleBasePath}/chat/private/$suffix');
                        });
                      },
                    ),
                    if (conversations.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      for (final item in conversations.take(5))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ConversationRow(
                            name: _readPath(item, ['partner', 'display_name']),
                            subtitle: _asMap(item['latest_message']).isEmpty
                                ? 'No messages yet'
                                : _readString(
                                    _asMap(item['latest_message']), 'body'),
                            unreadCount: _readInt(item, 'unread_count'),
                            selected: selectedUser.isNotEmpty &&
                                _readInt(_asMap(item['partner']), 'id') ==
                                    _readInt(selectedUser, 'id'),
                            onTap: () {
                              final conversationPartner = _readInt(
                                _asMap(item['partner']),
                                'id',
                              );
                              setState(() {
                                selectedUserId = conversationPartner;
                                privateFuture = widget.api.get(
                                  '${widget.roleBasePath}/chat/private/?user_id=$conversationPartner',
                                );
                              });
                            },
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _HeaderRow(
                title: selectedUser.isEmpty
                    ? 'Messages'
                    : _readString(selectedUser, 'display_name'),
                trailing: Text(
                  '${privateMessages.length} messages',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF61706C),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 14),
              if (privateMessages.isEmpty)
                _ManagementRecordCard(
                  title: selectedUser.isEmpty
                      ? 'Choose a person'
                      : _readString(selectedUser, 'display_name'),
                  description: selectedUser.isEmpty
                      ? 'Select a teammate to view an existing conversation or start a new one.'
                      : 'No private messages yet. Start the thread with a concise update.',
                  icon: selectedUser.isEmpty
                      ? Icons.person_search_rounded
                      : Icons.mark_chat_unread_rounded,
                  secondaryActionLabel: _tr(context, 'Send'),
                  onSecondaryAction: participants.isEmpty
                      ? null
                      : () => _sendPrivateMessage(participants),
                )
              else
                for (final item in privateMessages) ...[
                  _ChatMessageRow(
                    name: _readPath(item, ['sender', 'display_name']),
                    body: _readString(item, 'body'),
                    meta: _readPath(item, ['read_receipt', 'label']),
                    own: selectedUser.isNotEmpty &&
                        _readInt(_asMap(item['sender']), 'id') !=
                            _readInt(selectedUser, 'id'),
                  ),
                  const SizedBox(height: 14),
                ],
            ],
          ],
        );
      },
    );
  }
}
