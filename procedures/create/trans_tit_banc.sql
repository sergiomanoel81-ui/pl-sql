declare
 
nr_seq_movto_trans_orig_w number(10);
 
begin
    GERAR_MOVTO_TIT_BAIXA(28113, --<< Numero do titulo a pagar
                          5, --<< Sequencia da baixa do titulo a pagar
                          'P', --<< P = Pagar, R = Receber
                          'sergio.cerqueir', --<< Usuário para registrar
                          'S');
 
    select max(nr_sequencia)
      into nr_seq_movto_trans_orig_w
      from movto_trans_financ x
     where x.nr_seq_titulo_pagar = 28113 --<< Numero do titulo a pagar
       and x.vl_transacao > 0;
    update movto_trans_financ a
      set a.nr_seq_movto_orig = nr_seq_movto_trans_orig_w,
          a.ie_estorno = 'E',
          a.dt_referencia_saldo = (select max(x1.dt_referencia_saldo)
                                     from movto_trans_financ x1
                                    where x1.nr_sequencia = nr_seq_movto_trans_orig_w)
    where a.vl_transacao < 0
      and a.nr_seq_titulo_pagar = 28113; --<< Numero do titulo a pagar
    commit;
 
end;
 
