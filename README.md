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

**Conexão com a van — dois caminhos:**

| Caminho | Quem inicia | O responsável… | Aprovação |
|---|---|---|---|
| **Convite da família** (recomendado) | Motorista, na ficha do aluno (*Convidar*) | toca no link do WhatsApp ou digita o código (ex.: `K7P-2QX`) e **aceita** — filho, escola e rota já vêm preenchidos | Não |
| **Código geral da van** (`VAN-4821`) | Responsável que chega sozinho | confirma a van e preenche os dados do filho | Sim, em *Gestão › Alunos › Pedidos* |

O convite é de uso único, vale 7 dias, pode ser cancelado e inclui os irmãos (mesmo responsável).
Ao cadastrar um aluno novo, o app já abre o convite para enviar à família.

### Motorista
| Aba | O que faz |
|---|---|
| **Início** | Próxima viagem com um botão **Iniciar viagem**, pendências do dia e agenda. |
| **Rotas** | Criar/editar/excluir rotas: horário de saída, van, escolas atendidas, **quem vai** em cada rota, ordem das paradas (arrastar) e **otimizar ordem** (menor caminho). |
| **Finanças** | Gráfico dos últimos 6 meses (previsto × recebido), recebido/a receber/atrasado, ticket médio, inadimplência, **cobrar atrasados em lote** (mensagem pronta para WhatsApp), gerar mensalidades e registrar pagamentos. |
| **Gestão** | Alunos (com **convite para a família** e **pedidos** para aprovar), **escolas** (nome, endereço, horários), **vans** (apelido, modelo, placa, lugares), código da van, aparência e preferências da viagem. |

**Viagem ao vivo:** mapa com a van se movendo, chamada por parada (embarcou / não veio / entregue),
irmãos agrupados na mesma parada, ausências avisadas já fora da rota, avanço automático e
**botão de emergência** que alerta todas as famílias.

### No dia a dia (ideias estudadas no Van Escola)
- **Rota do dia × rota padrão:** "Quem vai hoje" muda só o dia; "Salvar hoje como padrão" torna fixo; "Desfazer" volta ao padrão.
- **Ausência com prazo:** o responsável marca ausência ou **"Vai sim"** (marcar presença) até a rota daquele sentido começar; depois, só com o motorista.
- **Paradas restantes:** o mapa do responsável mostra "faltam N paradas antes de você".
- **Aviso de GPS atrasado:** se o celular do motorista perde sinal, as famílias veem a última posição e um aviso (na demonstração, toque na antena durante a viagem).
- **Avisar que estou chegando:** botão do motorista a caminho de cada casa.
- **Rota em dois aparelhos:** antes de iniciar, o app avisa se a van já está em rota em outro celular (na demonstração, o auxiliar Paulo com a "Azulzinha").
- **Convite = login, com escopos:** o responsável entra só com o código (sem senha). O motorista pode convidar outro familiar como **"Só acompanhar"** (vê mapa e avisos) ou **"Ver e agir"**.

### Tutoriais interativos
Ao tocar em uma aba pela primeira vez no uso do app, abre um pop-up com o passo a passo daquela aba
(conteúdo diferente para motorista e responsável). Dá para deslizar entre as etapas e marcar
**Não mostrar novamente** — a escolha fica salva no aparelho. Em *Ajustes/Gestão › Rever tutoriais*
eles voltam a aparecer. O conteúdo fica em `lib/tutoriais/conteudo.dart`.

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
├── tutoriais/                # conteúdo e pop-up dos tutoriais por aba
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
- [ ] **Convites no backend:** documento `convites/{codigo}` (motorista, alunos, validade, uso) validado por uma Cloud Function; link com **App Links/Universal Links** (`app_links`) abrindo direto no convite.
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
