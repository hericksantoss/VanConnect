import 'package:flutter/cupertino.dart';

class PassoTutorial {
  const PassoTutorial({required this.icone, required this.titulo, required this.texto, this.destaques = const []});

  final IconData icone;
  final String titulo;
  final String texto;

  /// Pequenas "etiquetas" que mostram os botões/termos que a pessoa vai ver na tela.
  final List<String> destaques;
}

class Tutorial {
  const Tutorial({required this.aba, required this.passos});

  final String aba;
  final List<PassoTutorial> passos;
}

/// Chaves no formato "perfil.aba".
const tutoriais = <String, Tutorial>{
  // ------------------------------------------------------------ MOTORISTA
  'motorista.inicio': Tutorial(aba: 'Início', passos: [
    PassoTutorial(
      icone: CupertinoIcons.play_fill,
      titulo: 'Sua viagem em um toque',
      texto: 'O cartão azul mostra a próxima viagem. Toque em Iniciar viagem e a localização é compartilhada com as famílias automaticamente.',
      destaques: ['Iniciar viagem', 'Localização automática'],
    ),
    PassoTutorial(
      icone: CupertinoIcons.checkmark_circle_fill,
      titulo: 'Chamada simples',
      texto: 'Em cada parada, toque ✓ quando o aluno embarcar ou ✗ se ele não veio. Irmãos ficam na mesma parada e quem avisou ausência já sai da rota.',
      destaques: ['✓ Embarcou', '✗ Não veio', 'Todos embarcaram'],
    ),
    PassoTutorial(
      icone: CupertinoIcons.exclamationmark_triangle_fill,
      titulo: 'Botão de emergência',
      texto: 'Durante a viagem, o triângulo vermelho no topo do mapa envia um alerta para todas as famílias da rota.',
      destaques: ['Alerta para todos'],
    ),
    PassoTutorial(
      icone: CupertinoIcons.bell_fill,
      titulo: 'O que precisa de você hoje',
      texto: 'Pedidos de novos alunos, ausências, pagamentos para confirmar e aniversários aparecem em "Para hoje".',
      destaques: ['Pedidos', 'Ausências', 'Pagamentos'],
    ),
  ]),
  'motorista.rotas': Tutorial(aba: 'Rotas', passos: [
    PassoTutorial(
      icone: CupertinoIcons.map_fill,
      titulo: 'Suas rotas por turno',
      texto: 'Cada turno tem ida (casa → escola) e volta. Toque em uma rota para ver o mapa e editar.',
      destaques: ['Ida', 'Volta'],
    ),
    PassoTutorial(
      icone: CupertinoIcons.slider_horizontal_3,
      titulo: 'Edite tudo em um lugar',
      texto: 'Ajuste o horário de saída, escolha a van, marque as escolas atendidas e defina quem vai em cada rota.',
      destaques: ['Saída', 'Van', 'Escolas', 'Editar quem vai'],
    ),
    PassoTutorial(
      icone: CupertinoIcons.wand_stars,
      titulo: 'Ordem das paradas',
      texto: 'Segure e arraste um aluno para mudar a ordem, ou toque em Otimizar ordem para o app calcular o menor caminho.',
      destaques: ['Arrastar', 'Otimizar ordem'],
    ),
    PassoTutorial(
      icone: CupertinoIcons.add_circled_solid,
      titulo: 'Nova rota',
      texto: 'Toque no + no canto superior. Os alunos do turno e da escola escolhidos entram sozinhos.',
      destaques: ['+ Criar nova rota'],
    ),
  ]),
  'motorista.financas': Tutorial(aba: 'Finanças', passos: [
    PassoTutorial(
      icone: CupertinoIcons.chart_bar_fill,
      titulo: 'Seu mês num olhar',
      texto: 'O gráfico mostra os últimos 6 meses: em cinza o previsto, em azul o recebido. Toque em uma barra para ver aquele mês.',
      destaques: ['Previsto', 'Recebido', '% recebido'],
    ),
    PassoTutorial(
      icone: CupertinoIcons.square_grid_2x2_fill,
      titulo: 'Indicadores',
      texto: 'Acompanhe quanto já entrou, quanto falta receber, o que está atrasado e o valor médio por aluno.',
      destaques: ['Recebido', 'A receber', 'Atrasado', 'Ticket médio'],
    ),
    PassoTutorial(
      icone: CupertinoIcons.paperplane_fill,
      titulo: 'Cobrar sem constrangimento',
      texto: 'Cobrar atrasadas copia mensagens gentis e prontas para você colar no WhatsApp de cada responsável.',
      destaques: ['Cobrar atrasadas'],
    ),
    PassoTutorial(
      icone: CupertinoIcons.creditcard_fill,
      titulo: 'Registrar pagamento',
      texto: 'Toque em uma mensalidade e escolha Pix, dinheiro ou transferência. Quando a família avisa "Já paguei", aparece Confirmar.',
      destaques: ['Pix', 'Dinheiro', 'Confirmar'],
    ),
  ]),
  'motorista.gestao': Tutorial(aba: 'Gestão', passos: [
    PassoTutorial(
      icone: CupertinoIcons.person_2_fill,
      titulo: 'Alunos e pedidos',
      texto: 'Aprove ou recuse os pedidos das famílias e edite os dados de cada aluno: escola, turno, endereço e mensalidade.',
      destaques: ['Aceitar', 'Recusar', 'Editar'],
    ),
    PassoTutorial(
      icone: CupertinoIcons.book_fill,
      titulo: 'Escolas',
      texto: 'Cadastre as escolas atendidas com endereço e horários de entrada e saída.',
      destaques: ['Entrada', 'Saída'],
    ),
    PassoTutorial(
      icone: CupertinoIcons.bus,
      titulo: 'Vans',
      texto: 'Cadastre suas vans com apelido, modelo, placa e número de lugares. Cada rota usa uma van.',
      destaques: ['Placa', 'Lugares'],
    ),
    PassoTutorial(
      icone: CupertinoIcons.paperplane_fill,
      titulo: 'Convide as famílias',
      texto: 'Na ficha do aluno, toque em Convidar: a família recebe um link já com o filho e a rota, e só precisa aceitar. Irmãos vão no mesmo convite.',
      destaques: ['Convidar', 'Uso único', 'Vale 7 dias'],
    ),
    PassoTutorial(
      icone: CupertinoIcons.qrcode,
      titulo: 'Código geral',
      texto: 'O código VAN-… serve para quem chega sozinho. Nesse caso a família preenche os dados e você aprova em Alunos › Pedidos.',
      destaques: ['VAN-4821', 'Pedidos'],
    ),
    PassoTutorial(
      icone: CupertinoIcons.moon_fill,
      titulo: 'Do seu jeito',
      texto: 'Escolha o modo claro, escuro ou automático e ajuste como a viagem funciona.',
      destaques: ['Claro', 'Escuro', 'Automático'],
    ),
  ]),

  // ---------------------------------------------------------- RESPONSÁVEL
  'responsavel.mapa': Tutorial(aba: 'Mapa', passos: [
    PassoTutorial(
      icone: CupertinoIcons.location_fill,
      titulo: 'Acompanhe ao vivo',
      texto: 'Quando a van sai, ela aparece andando no mapa até a sua casa e até a escola.',
      destaques: ['AO VIVO'],
    ),
    PassoTutorial(
      icone: CupertinoIcons.person_crop_circle_fill_badge_checkmark,
      titulo: 'Status do seu filho',
      texto: 'O painel embaixo mostra quanto falta para a van chegar, quando seu filho embarcou e quando chegou. Troque de filho no topo.',
      destaques: ['Chega em ~4 min', 'Está na van', 'Chegou'],
    ),
    PassoTutorial(
      icone: CupertinoIcons.calendar_badge_minus,
      titulo: 'Não vai hoje?',
      texto: 'Um toque avisa o motorista e a parada sai da rota, sem precisar mandar mensagem.',
      destaques: ['Não vai hoje'],
    ),
    PassoTutorial(
      icone: CupertinoIcons.hand_draw_fill,
      titulo: 'Mexa no mapa',
      texto: 'Arraste e use dois dedos para aproximar. O botão no canto superior direito centraliza tudo de novo.',
      destaques: ['Arrastar', 'Aproximar', 'Centralizar'],
    ),
  ]),
  'responsavel.filhos': Tutorial(aba: 'Filhos', passos: [
    PassoTutorial(
      icone: CupertinoIcons.person_2_fill,
      titulo: 'Tudo sobre cada filho',
      texto: 'Veja a escola, o horário das aulas, o horário em que a van busca e leva, e o endereço de embarque.',
      destaques: ['Escola', 'Horários', 'Endereço'],
    ),
    PassoTutorial(
      icone: CupertinoIcons.heart_fill,
      titulo: 'Cuidados de saúde',
      texto: 'Alergias e cuidados importantes aparecem para o motorista na hora da chamada.',
      destaques: ['Alergia', 'Medicação'],
    ),
    PassoTutorial(
      icone: CupertinoIcons.paperplane_fill,
      titulo: 'Adicionar um filho',
      texto: 'Toque no link que o motorista mandou pelo WhatsApp, ou toque no + e digite o código do convite. Vem tudo pronto: é só aceitar.',
      destaques: ['Código do convite', 'Aceitar convite'],
    ),
  ]),
  'responsavel.avisos': Tutorial(aba: 'Avisos', passos: [
    PassoTutorial(
      icone: CupertinoIcons.bell_fill,
      titulo: 'Linha do tempo do dia',
      texto: 'Embarque, chegada, avisos e alertas do motorista ficam registrados aqui com o horário.',
      destaques: ['Embarcou', 'Chegou', 'Alerta'],
    ),
    PassoTutorial(
      icone: CupertinoIcons.calendar_badge_minus,
      titulo: 'Marcar ausência',
      texto: 'Escolha hoje, amanhã ou outro dia, e se é só a ida, só a volta ou as duas.',
      destaques: ['Hoje', 'Amanhã', 'Só ida', 'Só volta'],
    ),
    PassoTutorial(
      icone: CupertinoIcons.arrow_left,
      titulo: 'Mudou de ideia?',
      texto: 'Deslize uma ausência para a esquerda para cancelar o aviso.',
      destaques: ['Deslizar para cancelar'],
    ),
  ]),
  'responsavel.pagamentos': Tutorial(aba: 'Pagamentos', passos: [
    PassoTutorial(
      icone: CupertinoIcons.creditcard_fill,
      titulo: 'O que está em aberto',
      texto: 'Veja o total a pagar e copie a chave Pix do motorista com um toque.',
      destaques: ['Copiar chave Pix'],
    ),
    PassoTutorial(
      icone: CupertinoIcons.checkmark_seal_fill,
      titulo: 'Já paguei',
      texto: 'Pagou fora do app? Toque em Já paguei: o motorista recebe o aviso e confirma o recebimento.',
      destaques: ['Já paguei', 'Confirmando', 'Paga'],
    ),
  ]),
  'responsavel.ajustes': Tutorial(aba: 'Ajustes', passos: [
    PassoTutorial(
      icone: CupertinoIcons.moon_fill,
      titulo: 'Aparência',
      texto: 'Use o modo claro, escuro ou automático (segue o celular).',
      destaques: ['Claro', 'Escuro', 'Automático'],
    ),
    PassoTutorial(
      icone: CupertinoIcons.bell_fill,
      titulo: 'Notificações',
      texto: 'Escolha se quer ser avisado quando a van estiver a caminho e quando seu filho embarcar ou chegar.',
      destaques: ['Van a caminho', 'Embarque e chegada'],
    ),
    PassoTutorial(
      icone: CupertinoIcons.book_fill,
      titulo: 'Rever tutoriais',
      texto: 'Marcou "não mostrar novamente" e quer ver de novo? Toque em Rever tutoriais.',
      destaques: ['Rever tutoriais'],
    ),
  ]),
};
