# conviva

A new Flutter project.

## Conta da equipe de suporte

Contas de suporte não podem ser criadas pelo aplicativo. Para provisionar uma:

1. No Firebase Console, crie o usuário em **Authentication > Users**, informando
   o e-mail e a senha inicial.
2. Copie o UID gerado e crie manualmente o documento `users/{uid}` no Firestore
   com `type: "support"`, `status: "active"` e `name`.
3. Use a opção **Equipe de suporte** na seleção de conta em modo de login.

Não é necessário informar `institutionId` para esse perfil. As regras impedem
que um usuário crie ou altere o próprio `type`; somente o procedimento
administrativo do Firebase Console pode conceder esse papel. Uma conta de
suporte ativa pode consultar pedidos aprovados, mas não pode ler nem listar
documentos de outros usuários em `users`, inclusive entre instituições. O painel
permite inserir o link de redefinição para entregá-lo ao responsável que aprovou.

O painel permite solicitar o e-mail inicial ou outro e-mail de redefinição. O
operador informa o código ELD; o app confere o hash contra o pedido, reserva a
tentativa com as regras e chama `sendPasswordResetEmail()`. O pedido só é marcado
como enviado depois que essa chamada retorna sucesso. Há um intervalo mínimo de
cinco minutos entre tentativas. Isso registra o resultado da chamada do SDK, não
comprova que o provedor entregou ou que alguém recebeu o e-mail. Depois, o novo
link é copiado da caixa central e inserido no painel. O app valida HTTPS e o
domínio configurado. A conta de suporte do app não concede acesso ao Firebase
Console nem à caixa de e-mail.

No perfil do idoso, a seção **Responsáveis pela recuperação** grava
`recoveryFamilyUid` e `recoveryCaregiverUid`. A família escolhida deve possuir
vínculo ativo com o idoso; o cuidador deve estar ativo na mesma instituição.
Hoje, o modelo do Conviva considera os cuidadores ativos da instituição como
elegíveis, pois ainda não há vínculo individual cuidador–idoso.

## Recuperação de senha do idoso (Etapas 2 a 6)

O pedido é criado diretamente pelo app, com sessão anônima do Firebase Auth.
Ative o provedor **Anonymous** em **Authentication > Sign-in method** e publique
as regras do Firestore:

```powershell
firebase deploy --project conviva-63d6a --only firestore:rules,firestore:indexes
```

O cadastro cria um índice privado `elderRecoveryLookups` cujo ID é o SHA-256
direto dos bytes UTF-8 do código ELD normalizado em maiúsculas, sem segredo,
salt ou chave privada. A consulta é pontual (sem listagem) e retorna somente
UID, instituição e UIDs dos responsáveis selecionados. O pedido não contém o
código ELD nem senha. A leitura é restrita ao solicitante, aos responsáveis
relacionados e, após aprovação, à equipe de suporte. As regras limitam também um
novo pedido por código a cada cinco minutos.

Contas existentes com responsáveis já escolhidos sincronizam o índice quando o
idoso abre o perfil; se ainda não escolheu os dois responsáveis, salve a seleção
no perfil. Para um backfill manual, crie `elderRecoveryLookups/{hash}` com os
campos `elderUid`, `institutionId`, `familyUid` e `caregiverUid`. O `hash` é
SHA-256 direto dos bytes UTF-8 do código normalizado, por exemplo,
`ELD12345678` (maiúsculas, sem espaços ou separadores). Não use o código em
texto como ID.

Esse hash não torna secreto um código ELD previsível: alguém que consiga
enumerar códigos possíveis pode calcular os hashes offline. O app cria/atualiza
o documento enquanto o idoso está autenticado, no cadastro ou ao carregar/salvar
os responsáveis. As regras validam esse vínculo com o perfil autenticado e
`getAfter()`, mas não há segredo confiável no cliente. O rate limit é por código,
não por sessão/dispositivo; sem backend confiável, App Check e controles do
Firebase reduzem abuso, mas não eliminam enumeração distribuída nem abuso por
clientes modificados.

Uma alternativa sem segredo no cliente é usar códigos ELD aleatórios com alta
entropia, o que torna a enumeração menos viável, mas exige uma migração dos
códigos existentes. Uma proteção robusta para códigos previsíveis requer mover
a busca para um backend confiável com HMAC/chave mantida no servidor, limitação
de taxa e monitoramento. Não coloque uma chave no Flutter: ela pode ser extraída
do aplicativo.

Para abrir um pedido individual ou decidir, o familiar precisa manter o
`familyLinks` ativo e a conta ativa. A lista histórica de pedidos continua
limitada ao UID gravado no pedido e a uma conta ativa; essa consulta por UID não
revalida o vínculo, mas o acesso individual e a decisão são negados se o vínculo
deixar de estar ativo. O pedido conserva os UIDs escolhidos quando foi criado,
portanto trocar o familiar/cuidador no perfil não redireciona pedidos antigos.
O modelo atual não tem uma atribuição independente de cuidador por idoso: o
cuidador de recuperação é escolhido no perfil dentre as contas ativas da mesma
instituição. O UID selecionado fica congelado no pedido e a conta do cuidador
precisa continuar ativa na instituição para abrir ou decidir o pedido.

O lookup pode conter `familyUid` e `caregiverUid` nulos na criação inicial do
perfil, mas as regras recusam criar o pedido sem ambos. O app informa que o
idoso precisa configurar os responsáveis antes de tentar novamente.

Contas de suporte não podem ler nem listar documentos de outros usuários. A tela
de suporte usa o UID do pedido e solicita que o operador informe o código ELD;
ela não precisa consultar o perfil completo do idoso. As regras do Firestore não
oferecem projeção de campos: se futuramente o suporte precisar ver nome/código,
use um documento de contexto mínimo, vinculado a um pedido aprovado e escrito
por fluxo confiável, em vez de liberar leitura de `users`.

Somente a fase pendente expira após 24 horas, calculadas a partir de `createdAt`
confiável do Firestore. Cada responsável registra sua própria decisão; uma
aprovação encerra a decisão imediatamente, enquanto uma rejeição isolada mantém
o pedido pendente e duas rejeições encerram-no. Os pedidos pendentes aparecem no sino de
notificações quando o familiar ou cuidador está usando o app. Sem backend no
plano Spark, não há push quando o app está fechado. A aprovação não altera a
senha. Depois que o suporte insere o link na coleção privada
`passwordRecoveryDeliveries`, somente o responsável que aprovou pode acessá-lo
e encaminhá-lo. A sessão anônima original do idoso só pode ler o link depois
desse encaminhamento. O link não é colocado em notificações nem conversas. O
pedido aprovado não expira junto com a janela de aprovação.

Os links ficam separados dos pedidos, não podem ser listados e são lidos apenas
pelo aprovador ou pela sessão anônima solicitante após o encaminhamento e antes
de `deliveryExpiresAt` (retenção local de uma hora; não é uma afirmação sobre a
validade do código OOB do Firebase). As regras negam a leitura assim que essa
data passa, mesmo que o Firestore ainda não tenha removido o documento. Para
limpeza física, configure no Firebase Console uma política TTL na coleção
`passwordRecoveryDeliveries`, campo `deliveryExpiresAt`. A exclusão por TTL é
assíncrona e não substitui as regras de leitura.

O ID do projeto e `authDomain` configurados no app são `conviva-63d6a` e
`conviva-63d6a.firebaseapp.com`; a expressão das regras permite esse domínio e o
caminho de ação do Firebase. O endereço efetivamente recebido por e-mail ainda
precisa ser conferido em um e-mail de teste e comparado com a lista de domínios
de ação do Firebase Console antes da publicação. As regras só validam formato e
destino aparente; não conseguem provar que o `oobCode` pertence à conta do idoso.

O estado `completed` é registrado quando o idoso autenticado volta ao app após
usar o link. As regras garantem que somente esse UID marque o pedido e que a
entrega seja removida no mesmo lote, mas não conseguem verificar se a senha foi
realmente redefinida ou se o código OOB foi consumido. `completed` é um registro
do fluxo no app, não prova absoluta da alteração de senha.

O botão
**Abrir no navegador** usa a página oficial de redefinição do Firebase. Depois,
ao entrar com o código ELD e a senha nova, o app só conclui pedidos encaminhados
cujo UID corresponde ao idoso autenticado; na mesma operação, remove o link e os
metadados temporários. O login bem-sucedido substitui a sessão anônima.

Se o Firebase indicar que o link expirou ou já foi usado, o operador pode pedir
outro e-mail enquanto o pedido estiver aprovado. Após o Firebase aceitar a nova
solicitação, o app remove a entrega anterior e registra o envio. O idoso continua
usando a tela normal de login; o app não captura o código de ação nem cria uma
página própria de senha.

O App Check foi avaliado, mas não é ativado/enforçado pelo app nesta etapa: isso
requer registrar cada plataforma e configurar o provedor no Firebase Console.
Recomenda-se ativar Play Integrity no Android e App Attest no iOS antes de impor
enforcement; App Check complementa, mas não substitui, o cooldown das regras.

Os testes de regras ficam em `firestore-tests`. Para executá-los, instale as
dependências dentro dessa pasta e use `npm test`; o Firebase Emulator Suite
precisa de uma instalação Java disponível. Os testes usam o projeto local
`demo-conviva-rules` e não publicam regras nem acessam dados de produção.

## Notificações Android

O sino do cabeçalho abre a caixa de entrada. Sem o plano Blaze, o app acompanha
mensagens enquanto está aberto e agenda lembretes de tarefas localmente no
Android. Os lembretes agendados podem tocar com o app fechado ou após reiniciar
o celular, mas o horário pode variar um pouco por causa das restrições de
bateria do Android. As preferências de notificações e, para familiares, a
opção do vínculo são respeitadas.

As mensagens não geram alerta quando o app está fechado usando somente o plano
gratuito: para isso é necessário um serviço de backend ativo para enviar push.
Para ativar o histórico de mensagens no sino, publique as regras do Firestore
no projeto `conviva-63d6a`:

```powershell
firebase deploy --project conviva-63d6a --only firestore:rules
```

O fluxo legado de redefinição do idoso ainda usa Cloud Functions; o novo fluxo
das Etapas 2 a 6 não usa Functions, Admin SDK nem plano Blaze. As Cloud
Functions existentes também podem enviar push de mensagens e verificar tarefas
em segundo plano. A publicação requer o plano Blaze. Para publicar as funções e
os índices Firestore no projeto Firebase, execute no diretório `mobile`:

```powershell
cd functions
npm.cmd install
npm.cmd run build
cd ..
firebase deploy --project conviva-63d6a --only functions,firestore:rules,firestore:indexes
```

O envio remoto de notificações de tarefas usa o Cloud Scheduler; os lembretes
locais não precisam dele.
