# Van Connect

Aplicativo de **transporte escolar** que conecta o motorista da van às famílias.
O responsável acompanha a van ao vivo num mapa, avisa ausências e vê as mensalidades;
o motorista organiza rotas, faz a chamada e controla o financeiro.

> **Status:** protótipo funcional. Os dados são fictícios e ficam em memória
> (somem ao fechar o app). Ver [Próximos passos](#próximos-passos).

Feito em **Flutter** — roda em **Android** e **iPhone (iOS)** com o mesmo código.

---

## Funcionalidades

### Responsável
| Aba | O que faz |
|---|---|
| **Mapa** | Mapa em tela cheia com a casa, a escola e a van ao vivo durante a viagem. Painel com status ("chega em ~4 min", "está na van", "chegou na escola"), botão **Não vai hoje** e contato do motorista. Alerta vermelho se o motorista acionar emergência. |
| **Filhos** | Escola, horários de aula, horário de busca/volta, endereço e cuidados de saúde de cada filho. Adicionar filho pelo **código da van**. |
| **Avisos** | Linha do tempo do dia (embarcou, chegou, emergência) e ausências marcadas (deslize para cancelar). |
| **Pagamentos** | Total em aberto, cópia da chave Pix e botão **Já paguei** (o motorista confirma). |
| **Ajustes** | Aparência (claro/escuro/automático) e notificações. |

**Conexão com a van:** código (`VAN-4821`) → "Esta é a sua van?" → dados do filho → pedido enviado → o motorista aprova.

### Motorista
| Aba | O que faz |
|---|---|
| **Início** | Próxima viagem com um botão **Iniciar viagem**, pendências do dia e agenda. |
| **Rotas** | Criar/editar/excluir rotas: horário de saída, van, escolas atendidas, **quem vai** em cada rota, ordem das paradas (arrastar) e **otimizar ordem** (menor caminho). |
| **Finanças** | Gráfico dos últimos 6 meses (previsto × recebido), recebido/a receber/atrasado, ticket médio, inadimplência, **cobrar atrasados em lote** (mensagem pronta para WhatsApp), gerar mensalidades e registrar pagamentos. |
| **Gestão** | Alunos (com **pedidos** para aprovar), **escolas** (nome, endereço, horários), **vans** (apelido, modelo, placa, lugares), código da van, aparência e preferências da viagem. |

**Viagem ao vivo:** mapa com a van se movendo, chamada por parada (embarcou / não veio / entregue),
irmãos agrupados na mesma parada, ausências avisadas já fora da rota, avanço automático e
**botão de emergência** que alerta todas as famílias.

### Visual
- Padrão **azul, cinza e branco**, com **modo escuro** (Ajustes › Aparência).
- Estilo **iOS**: títulos grandes, listas agrupadas, ícones suaves, barra de abas com desfoque,
  folhas de ação, transições laterais e rolagem elástica — em Android e iPhone.
- Mapa real (**OpenStreetMap**) com filtro cinza-claro / escuro combinando com o app.

---

## Como rodar

Pré-requisitos: [Flutter](https://docs.flutter.dev/get-started/install) 3.44+ (Dart 3.12+).

```bash
flutter pub get
flutter run              # escolhe o aparelho conectado
flutter run --release    # versão rápida (sem modo debug)
flutter test             # testes
```

### Android
Conecte o celular com **depuração USB** ativada e rode `flutter run`.
Para gerar o instalador: `flutter build apk --release` (arquivo em `build/app/outputs/flutter-apk/`).

### iPhone (iOS)
Compilar para iPhone exige **macOS com Xcode** (limitação da Apple).
1. Num Mac: `flutter pub get` → `cd ios && pod install` → abra `ios/Runner.xcworkspace` no Xcode.
2. Em *Signing & Capabilities*, escolha seu time (Apple ID) e ajuste o *Bundle Identifier* (`app.vanconnect.vanConnect`).
3. Conecte o iPhone e rode `flutter run`.

Sem Mac? Use um serviço de build na nuvem como **Codemagic** ou **GitHub Actions (runner macOS)**
para gerar o `.ipa` e enviar ao TestFlight.

---

## Estrutura

```
lib/
├── main.dart                 # app, temas claro/escuro, rotas por perfil
├── app/
│   ├── tema.dart             # Paleta (azul/cinza/branco), tema iOS, rolagem elástica
│   └── formatos.dart         # moeda, datas e horários em pt-BR
├── dominio/modelos.dart      # Aluno, Escola, Veiculo, Trajeto, Viagem, Cobranca, Ausencia, Solicitacao
├── dados/semente.dart        # dados fictícios de demonstração
├── estado/van_store.dart     # estado do app, cadastros, simulação da viagem, relatórios
├── componentes/
│   ├── ui.dart               # kit visual (Secao, Linha, Botao, Segmentos, Formulario…)
│   ├── mapa.dart             # mapa (flutter_map) com rota e van animada
│   └── aparencia.dart        # seletor claro/escuro/automático
└── telas/
    ├── entrada/              # boas-vindas e escolha de perfil
    ├── motorista/            # início, rotas, rota, viagem, finanças, gestão, alunos
    └── responsavel/          # mapa, filhos, avisos, pagamentos, ajustes, conectar van
```

Estado com `ChangeNotifier` + `InheritedNotifier` (sem pacotes extras). A posição da van usa um
`ValueNotifier` separado: só o mapa redesenha a cada quadro, o resto da tela fica estável.

---

## Próximos passos

- [ ] **Backend e login** (Firebase Auth + Firestore, como no projeto original): trocar os métodos de `VanStore` por chamadas ao banco.
- [ ] **GPS real** do celular do motorista com serviço em segundo plano (`geolocator` + permissões Android/iOS).
- [ ] **Notificações push** para as famílias (Firebase Cloud Messaging).
- [ ] **Provedor de mapa para produção:** as imagens públicas do OpenStreetMap são só para testes
      ([política de uso](https://operations.osmfoundation.org/policies/tiles/)). Em produção, use MapTiler,
      Stadia Maps ou Mapbox (com chave) ou `google_maps_flutter`.
- [ ] Rotas pelas ruas de verdade (serviço de roteamento, ex.: OSRM).
- [ ] Ícone do app e tela de abertura (`flutter_launcher_icons`, `flutter_native_splash`).

---

## Versionamento

Fluxo sugerido:

```bash
git checkout -b feature/nome-da-melhoria   # nova funcionalidade
git add .
git commit -m "Descreve o que mudou"
git push -u origin feature/nome-da-melhoria # depois abra um Pull Request para a main
```

Mapa: dados © [OpenStreetMap](https://www.openstreetmap.org/copyright) contributors.
