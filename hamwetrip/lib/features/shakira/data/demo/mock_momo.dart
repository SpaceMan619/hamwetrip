import '../../../../../data/models/momo_transaction.dart';

final List<MomoTransaction> mockMomoTransactions = [
  MomoTransaction(
    id: 'momo_1',
    name: 'Kamanzi',
    initials: 'KZ',
    maskedPhone: '078X-XXX-123',
    amount: 40000,
    type: MomoType.send,
    status: MomoStatus.pending,
  ),
  MomoTransaction(
    id: 'momo_2',
    name: 'Shakira',
    initials: 'SK',
    maskedPhone: '078X-XXX-456',
    amount: 20000,
    type: MomoType.send,
    status: MomoStatus.pending,
  ),
  MomoTransaction(
    id: 'momo_3',
    name: 'Aime',
    initials: 'AJ',
    maskedPhone: '078X-XXX-789',
    amount: 46000,
    type: MomoType.send,
    status: MomoStatus.pending,
  ),
  MomoTransaction(
    id: 'momo_4',
    name: 'Jean',
    initials: 'JN',
    maskedPhone: '078X-XXX-321',
    amount: 15000,
    type: MomoType.receive,
    status: MomoStatus.pending,
  ),
  MomoTransaction(
    id: 'momo_5',
    name: 'Umuhoza',
    initials: 'UM',
    maskedPhone: '078X-XXX-654',
    amount: 85000,
    type: MomoType.receive,
    status: MomoStatus.completed,
  ),
];
