# conviva

A new Flutter project.

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

Opcionalmente, com o plano Blaze, as Cloud Functions também enviam push de
mensagens e verificam tarefas em segundo plano. Para publicar esse modo no
projeto Firebase, execute no diretório `mobile`:

```powershell
cd functions
npm.cmd install
npm.cmd run build
cd ..
firebase deploy --project conviva-63d6a --only functions,firestore:rules,firestore:indexes
```

O envio remoto de notificações de tarefas usa o Cloud Scheduler e requer o
plano Blaze. Esse modo remoto é opcional; os lembretes locais não precisam dele.
