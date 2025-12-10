BEGIN
    GERAR_MOVTO_ADIANT_PAGO(
        nr_adiantamento_p => 123,        -- número do adiantamento
        nm_usuario_p      => 'sergio.cerqueir',     -- seu usuário
        dt_movto_p        => NULL       -- data do movimento (ou NULL para usar a data do adiantamento)
    );
END;
/
