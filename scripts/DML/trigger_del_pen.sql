/* =============================================================================
   Objeto    : CSB_MOVTO_TRANS_FINANC_BEF_DEL   (TRIGGER - BEFORE DELETE, ROW)
   Tabela    : MOVTO_TRANS_FINANC
   Autor     : Sergio Cerqueira - TI Corporativo / Grupo CSB
   Data      : 2026-06-12
   -----------------------------------------------------------------------------
   OBJETIVO
     Permitir a exclusao de uma MOVTO_TRANS_FINANC que esteja apenas PENDENTE
     de conciliacao, removendo automaticamente os registros filhos em
     CONCIL_BANC_PEND_TASY. Bloquear a exclusao quando a conciliacao ja estiver
     REALIZADA (IE_CONCILIACAO = 'S').

   CONTEXTO / PROBLEMA
     A exclusao de uma MOVTO_TRANS_FINANC com pendencia de conciliacao falha com:
        ORA-02292: restricao de integridade (TASY.CONBAPT_MOVTRFI_FK) violada -
                   registro filho localizado
     A FK CONBAPT_MOVTRFI_FK (CONCIL_BANC_PEND_TASY.NR_SEQ_MOVTO_TRANS ->
     MOVTO_TRANS_FINANC.NR_SEQUENCIA) NAO possui ON DELETE CASCADE.
     A trigger nativa MOVTO_TRANS_FINANC_DELETE encontra-se DISABLED, portanto o
     unico bloqueio de banco na exclusao e a propria FK.

   REGRA DE NEGOCIO
     IE_CONCILIACAO = 'S'  -> conciliacao REALIZADA       -> BLOQUEIA (ORA-20001)
     IE_CONCILIACAO = 'N'  -> pendente / nao conciliado   -> limpa filhos e libera

   FUNCIONAMENTO
     BEFORE DELETE FOR EACH ROW:
       1. Respeita o bypass padrao TASY (get_ie_executar_trigger = 'N' -> sai).
       2. Se IE_CONCILIACAO = 'S' -> raise_application_error(-20001).
       3. Caso contrario -> DELETE dos filhos em CONCIL_BANC_PEND_TASY.

   NOTA TECNICA
     - FK em modo IMMEDIATE e validada ao final do statement; remover os filhos
       no BEFORE DELETE satisfaz a constraint a tempo (cascade manual via trigger).
     - Esta trigger atua sobre o DELETE REAL (via SQL ou qualquer fluxo que emita
       o DELETE no banco). A grid "Controle Bancario" executa uma consistencia de
       APLICACAO *antes* de enviar o DELETE, exibindo o aviso "Esta movimentacao
       possui conciliacao pendente...". Para excluir uma transacao PENDENTE pela
       grid, rodar antes CSB_LIMPAR_PEND_CONCIL e RECARREGAR a tela.
       [PENDENTE] Confirmacao do comportamento da grid apos a limpeza da pendencia
       ainda nao testada na interface (somente validado em SQL).

   TABELAS ENVOLVIDAS
     MOVTO_TRANS_FINANC      (pai  - registro sendo excluido)
     CONCIL_BANC_PEND_TASY   (filho - pendencias de conciliacao)
     FK CONBAPT_MOVTRFI_FK   (sem ON DELETE CASCADE)

   DEPENDENCIAS
     wheb_usuario_pck.get_ie_executar_trigger   (bypass padrao TASY)

   CHANGELOG
     v1 (2026-06-12) - Criacao. Validado em SQL: transacao pendente e excluida
                       (filhos limpos automaticamente) e transacao realizada
                       e bloqueada com ORA-20001 (via ORA-04088 no DELETE).
   ============================================================================= */

CREATE OR REPLACE TRIGGER csb_movto_trans_financ_bef_del
BEFORE DELETE ON movto_trans_financ
FOR EACH ROW
BEGIN
   -- Bypass padrao TASY (remover este bloco se quiser bloqueio inbypassavel)
   IF (wheb_usuario_pck.get_ie_executar_trigger = 'N') THEN
      RETURN;
   END IF;

   -- Conciliacao REALIZADA: bloqueia
   IF (:OLD.ie_conciliacao = 'S') THEN
      raise_application_error(-20001,
         'Movimentacao com conciliacao REALIZADA nao pode ser excluida.');
   END IF;

   -- Pendente: remove os filhos para satisfazer a FK CONBAPT_MOVTRFI_FK
   DELETE FROM concil_banc_pend_tasy
    WHERE nr_seq_movto_trans = :OLD.nr_sequencia;
END csb_movto_trans_financ_bef_del;
/

/* -----------------------------------------------------------------------------
   ANEXO - Consultas de diagnostico utilizadas (referencia)
   -----------------------------------------------------------------------------
   -- Trigger nativa de delete (constatado DISABLED):
   SELECT trigger_name, status, triggering_event
     FROM user_triggers
    WHERE table_name = 'MOVTO_TRANS_FINANC' AND triggering_event LIKE '%DELETE%';

   -- FK bloqueadora (sem cascade):
   SELECT constraint_name, delete_rule, status
     FROM user_constraints WHERE constraint_name = 'CONBAPT_MOVTRFI_FK';

   -- Dominio do flag (S=51988 realizada / N=930 nao):
   SELECT ie_conciliacao, COUNT(*) FROM movto_trans_financ GROUP BY ie_conciliacao;

   -- Raio-x de uma transacao (estado + qtd de pendencias):
   SELECT m.nr_sequencia, m.ie_conciliacao, m.nr_seq_concil,
          (SELECT COUNT(*) FROM concil_banc_pend_tasy p
            WHERE p.nr_seq_movto_trans = m.nr_sequencia) qt_pend
     FROM movto_trans_financ m WHERE m.nr_sequencia = :nr_seq;
   ----------------------------------------------------------------------------- */
