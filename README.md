# Van Connect

Aplicativo de **transporte escolar** que conecta o motorista da van às famílias.
O responsável acompanha a van ao vivo num mapa, avisa ausências e vê as mensalidades;
o motorista organiza rotas, faz a chamada e controla o financeiro.

> **Status:** protótipo funcional. O login com Google/Facebook é **simulado** (ver
> [Login de verdade](#login-de-verdade-google-e-facebook)) e os dados ficam em memória —
> só a sessão (quem entrou) fica salva no aparelho. Ver [Próximos passos](#próximos-passos).

Feito em **Flutter** — roda em **Android** e **iPhone (iOS)** com o mesmo código.

---

## Funcionalidades

### Entrada e contas
| Perfil | Como entra |
|---|---|
| **Motorista** | Cria a conta com **Google**, **Facebook** ou **e-mail** → preenche os dados pessoais (nome, **CPF validado**, RG, CNH opcional, WhatsApp) → cadastra a van (apelido, modelo, **placa validada** — antiga ou Mercosul —, lugares). |
| **Responsável** | Cria a conta do mesmo jeito e **só acessa o app com o código da van**: o **convite da família** libera na hora; o **código geral** (`VAN-…`) vira um pedido e o app mostra "aguardando aprovação" até o motorista aceitar. |

- A sessão fica salva: ao reabrir o app, a pessoa continua logada. **Sair** fica em *Gestão* / *Ajustes*.
- A conta lembra os filhos já liberados: saiu e entrou de novo com a mesma conta, não precisa do código outra vez.
- Cada motorista vê **só as próprias vans** (pode ter uma principal e uma reserva); nenhuma van é compartilhada com outro motorista.
- Na tela inicial, **Ver demonstração: Motorista / Família** abre o app para conhecer sem criar conta.

### Responsável
| Aba | O que faz |
|---|---|
| **Mapa** | Mapa em tela cheia com a casa, a escola e a van ao vivo durante a viagem. O **aviso mais recente** aparece ao entrar. Painel com status ("chega em ~4 min", "está na van", "chegou na escola"), botão **Não vai hoje** e contato do motorista. Alerta vermelho em emergência. |
| **Filhos** | Escola, horários, horário de busca/volta, endereço e cuidados de saúde de cada filho. Adicionar filho pelo convite ou pelo código da van. |
| **Avisos** | **Recados do motorista** (cobranças e lembretes com a chave Pix para copiar), linha do tempo do dia e ausências marcadas. |
| **Pagamentos** | Total em aberto, cópia da **chave Pix cadastrada pelo motorista** e botão **Já paguei** (o motorista confirma). |
| **Ajustes** | Conta, aparência (claro/escuro/automático), notificações e sair. |

O responsável **não vê a lista de colégios do motorista**: no pedido ele escreve o nome da escola
e o motorista confirma (ou corrige) antes de aceitar.

**Conexão com a van — dois caminhos:**

| Caminho | Quem inicia | O responsável… | Aprovação |
|---|---|---|---|
| **Convite da família** (recomendado) | Motorista, na ficha do aluno (*Convidar*) | toca no link do WhatsApp ou digita o código (ex.: `K7P-2QX`) e **aceita** — filho, escola e rota já vêm preenchidos | Não |
| **Código geral da van** (`VAN-4821`) | Responsável que chega sozinho | confirma a van e preenche nome, escola, turno e **endereço pelo CEP** | Sim, em *Gestão › Alunos › Pedidos* |

O convite é de uso único, vale 7 dias, pode ser cancelado e inclui os irmãos (mesmo responsável).

### Motorista
| Aba | O que faz |
|---|---|
| **Início** | Aviso mais recente e **sino** com a central de avisos, próxima viagem com **Iniciar viagem**, pendências do dia e agenda. |
| **Rotas** | Criar/editar/excluir rotas: horário, van, colégios atendidos (com **cadastrar novo colégio** ali mesmo), **quem vai**, ordem das paradas (arrastar) e **otimizar ordem**. |
| **Finanças** | Anel com o **% recebido** do mês, blocos coloridos (recebido / a receber / atrasado), **cadastro da chave Pix**, **cobrar atrasados no app** (o aviso já leva a chave Pix), **lembrar antes do vencimento**, confirmar pagamentos informados, gerar mensalidades e gráfico de 6 meses. |
| **Gestão** | **Meus dados** (toque no nome), alunos (novo passageiro com **seleção de colégio** e endereço por CEP; **editar pedidos** enviados pelas famílias), **colégios** (cadastrar/editar/excluir), **vans** (principal e reserva), código da van e preferências. |

**Viagem ao vivo:** mapa com a van se movendo, chamada por parada (embarcou / não veio / entregue),
irmãos agrupados, ausências avisadas fora da rota, avanço automático e **botão de emergência**.

**Localização obrigatória:** para iniciar a viagem o GPS precisa estar ligado e com permissão —
se não estiver, o app bloqueia o início e fica pedindo para ligar (as famílias acompanham em tempo real).
Se o GPS for desligado no meio da viagem, aparece um alerta vermelho com o botão **Ligar localização**.

### Endereços pelo CEP
O endereço de embarque e o dos colégios são preenchidos pelo **CEP** (consulta no
[ViaCEP](https://viacep.com.br)); depois o app procura o ponto no mapa
([Nominatim/OpenStreetMap](https://nominatim.org)) e abre uma tela para **confirmar a casa no mapa**
(arrastar até a porta certa).

### No dia a dia (ideias estudadas no Van Escola)
- **Rota do dia × rota padrão:** "Quem vai hoje" muda só o dia; "Salvar hoje como padrão" torna fixo.
- **Ausência com prazo:** o responsável marca ausência ou **"Vai sim"** até a rota daquele sentido começar.
- **Paradas restantes:** o mapa do responsável mostra "faltam N paradas antes de você".
- **Aviso de GPS atrasado:** sem sinal, as famílias veem a última posição e um aviso.
- **Avisar que estou chegando:** botão do motorista a caminho de cada casa.
- **Rota em dois aparelhos:** antes de iniciar, o app avisa se a van já está em rota em outro celular da mesma conta.
- **Convite com escopos:** o motorista pode convidar outro familiar como **"Só acompanhar"** ou **"Ver e agir"**.

### Tutoriais interativos
Ao tocar em uma aba pela primeira vez, abre um pop-up com o passo a passo daquela aba (diferente
para motorista e responsável), com **Não mostrar novamente**. Em *Ajustes/Gestão › Rever tutoriais*
eles voltam. O conteúdo fica em `lib/tutoriais/conteudo.dart`.

### Visual
- Padrão **azul, cinza e branco**, com **modo escuro** (Ajustes › Aparência).
- Componentes próprios, neutros entre Android e iPhone: diálogos e folhas leves, seletores em pílula,
  chaves e botões arredondados.
- Ícone do app baseado no logo VanConnect (van escolar + sinal de conexão).
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

Sem Mac? Use **Codemagic** ou **GitHub Actions (runner macOS)** para gerar o `.ipa` e enviar ao TestFlight.

### Ícone do app
As imagens ficam em `icone/` (geradas a partir de `assets/logo.png` por `icone/gerar.py`, com Pillow).
Para aplicar em Android e iOS: `dart run flutter_launcher_icons`.

---

## Login de verdade (Google e Facebook)

O app já usa uma interface única, `AutenticacaoServico` (`lib/servicos/autenticacao_servico.dart`).
Hoje ela é `AutenticacaoDemonstracao` (pede nome e e-mail). Para o login real:

1. **Firebase:** crie um projeto no [console do Firebase](https://console.firebase.google.com),
   adicione os apps Android (`app.vanconnect.van_connect`) e iOS (`app.vanconnect.vanConnect`) e rode
   `flutterfire configure` (gera `lib/firebase_options.dart`).
2. **Pacotes:** `flutter pub add firebase_core firebase_auth google_sign_in flutter_facebook_auth`.
3. **Google:** em *Authentication › Sign-in method* ative o Google. No Android, cadastre o **SHA-1** e o
   **SHA-256** da chave de assinatura (`cd android && ./gradlew signingReport`). No iOS, adicione o
   `REVERSED_CLIENT_ID` do `GoogleService-Info.plist` em *URL Types*.
4. **Facebook:** crie o app em [developers.facebook.com](https://developers.facebook.com), ative o login
   do Facebook no Firebase (App ID + App Secret) e configure `facebook_app_id` / `facebook_client_token`
   no `strings.xml` (Android) e as chaves `FacebookAppID`, `FacebookClientToken` e o URL scheme
   `fb<APP_ID>` no `Info.plist` (iOS), como na documentação do `flutter_facebook_auth`.
5. **E-mail:** ative *E-mail/senha* no Firebase.
6. Crie `AutenticacaoFirebase implements AutenticacaoServico` (com `GoogleSignIn().signIn()`,
   `FacebookAuth.instance.login()` e `FirebaseAuth.instance.signInWith…`) e passe no `main.dart`:
   `VanStore(auth: AutenticacaoFirebase())`. O resto do app não muda.

Os dados do cadastro (CPF, RG, CNH, van) e os vínculos família ↔ aluno devem ir para o banco
(ex.: Firestore), com regras de acesso por conta: cada van pertence a um único motorista.

---

## Estrutura

```
lib/
├── main.dart                 # app, temas, sessão salva e troca de perfil
├── app/
│   ├── tema.dart             # Paleta (azul/cinza/branco), claro/escuro
│   ├── formatos.dart         # moeda, datas e horários em pt-BR
│   ├── geo.dart              # posição no mapa ↔ latitude/longitude
│   └── validacoes.dart       # CPF, placa, telefone, e-mail
├── servicos/
│   ├── autenticacao_servico.dart  # login (demonstração; Firebase em produção)
│   ├── sessao_salva.dart          # quem está logado (shared_preferences)
│   ├── endereco_servico.dart      # CEP (ViaCEP) e localização (Nominatim)
│   └── localizacao_servico.dart   # GPS obrigatório (geolocator)
├── tutoriais/                # conteúdo e pop-up dos tutoriais por aba
├── dominio/modelos.dart      # Aluno, Escola, Endereco, Veiculo, Trajeto, Viagem, Cobranca, Aviso, ChavePix…
├── dados/semente.dart        # dados fictícios de demonstração
├── estado/van_store.dart     # estado do app, cadastros, avisos, simulação da viagem, relatórios
├── componentes/
│   ├── ui.dart               # kit visual (Secao, Linha, Botao, Segmentos, Formulario, diálogos…)
│   ├── mascaras.dart         # máscaras de CPF, telefone e placa
│   ├── mapa.dart             # mapa (flutter_map) com rota e van animada
│   └── aparencia.dart        # seletor claro/escuro/automático
└── telas/
    ├── entrada/              # boas-vindas, conta (Google/Facebook/e-mail), cadastro do motorista, código da van
    ├── comum/                # endereço por CEP + mapa, colégios, central de avisos
    ├── motorista/            # início, rotas, viagem, finanças, gestão, passageiros, localização obrigatória
    └── responsavel/          # mapa, filhos, avisos, pagamentos, ajustes, conectar van, aguardando aprovação
icone/                        # imagens-fonte do ícone do app
```

Estado com `ChangeNotifier` + `InheritedNotifier` (sem pacotes extras). A posição da van usa um
`ValueNotifier` separado: só o mapa redesenha a cada quadro, o resto da tela fica estável.

---

## Próximos passos

- [ ] **Backend:** Firebase Auth (ver acima) + Firestore — trocar os métodos de `VanStore` por chamadas ao banco.
- [ ] **GPS em segundo plano** durante a viagem (serviço em primeiro plano no Android, *background modes* no iOS).
- [ ] **Convites no backend:** documento `convites/{codigo}` validado por uma Cloud Function; link com **App Links/Universal Links**.
- [ ] **Notificações push** (Firebase Cloud Messaging) para os avisos que hoje ficam dentro do app.
- [ ] **Provedores para produção:** as imagens do OpenStreetMap e o Nominatim públicos são para testes
      ([política de uso](https://operations.osmfoundation.org/policies/tiles/)). Em produção, use MapTiler,
      Stadia Maps, Mapbox ou Google (com chave) para mapa e geocodificação.
- [ ] Rotas pelas ruas de verdade (serviço de roteamento, ex.: OSRM).
- [ ] Tela de abertura (`flutter_native_splash`).

---

## Versionamento

Fluxo sugerido:

```bash
git checkout -b feature/nome-da-melhoria   # nova funcionalidade
git add .
git commit -m "Descreve o que mudou"
git push -u origin feature/nome-da-melhoria # depois abra um Pull Request para a main
```

Mapa: dados © [OpenStreetMap](https://www.openstreetmap.org/copyright) contributors. CEP: ViaCEP.
