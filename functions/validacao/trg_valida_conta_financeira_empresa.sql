/*
================================================================================
TRIGGER: CSB_TP_CLASSIF_CONTA_FINANC
================================================================================
DESCRIÇÃO:
  Valida se a conta financeira informada na classificação do título a pagar
  pertence à mesma empresa do usuário logado no sistema.

TABELA: 
  TITULO_PAGAR_CLASSIF

EVENTO: 
  BEFORE UPDATE

FUNCIONALIDADE:
  - Impede que o usuário associe uma conta financeira de outra empresa
  - Valida a empresa da conta financeira vs empresa do estabelecimento logado
  - Exibe mensagem detalhada informando as empresas envolvidas no erro

REGRA DE NEGÓCIO:
  Um usuário só pode utilizar contas financeiras da empresa em que está logado

DEPENDÊNCIAS:
  - Tabela: conta_financeira
  - Package: wheb_usuario_pck
  - Package: wheb_mensagem_pck
  - Function: obter_empresa_estab()

AUTOR: [Seu nome]
DATA: 28/10/2025
================================================================================
*/

CREATE OR REPLACE TRIGGER "CSB_TP_CLASSIF_CONTA_FINANC"
BEFORE UPDATE ON TITULO_PAGAR_CLASSIF
FOR EACH ROW
DECLARE
    cd_emp_conta_financ_w empresa.cd_empresa%type;
BEGIN
    IF (wheb_usuario_pck.get_ie_executar_trigger = 'S') THEN
        IF (:new.nr_seq_conta_financ IS NOT NULL) THEN
            SELECT cf.cd_empresa
              INTO cd_emp_conta_financ_w
              FROM conta_financeira cf
             WHERE cf.cd_conta_financ = :new.NR_SEQ_CONTA_FINANC;

            IF (cd_emp_conta_financ_w <> obter_empresa_estab(wheb_usuario_pck.get_cd_estabelecimento)) THEN
                wheb_mensagem_pck.exibir_mensagem_abort(
                    'A conta financeira ' || :new.NR_SEQ_CONTA_FINANC || 
                    '" não é dessa empresa. Empresa da conta financeira ' || cd_emp_conta_financ_w || 
                    ' - Empresa logada ' || obter_empresa_estab(wheb_usuario_pck.get_cd_estabelecimento));
            END IF; 
        END IF;
    END IF;
END;
/
