"""Gate de assinatura — regras puras (docs/plano_b2c.md Fase 3)."""
from app.assinatura.entitlement import tem_acesso
from app.assinatura.service import status_de


def test_assinante_tem_acesso_mesmo_alem_do_free_tier():
    assert tem_acesso(tem_assinatura_ativa=True, xp_total=999_999, limiar_gratis=18_000)


def test_sem_assinatura_dentro_do_free_tier_tem_acesso():
    assert tem_acesso(tem_assinatura_ativa=False, xp_total=17_900, limiar_gratis=18_000)


def test_sem_assinatura_alem_do_free_tier_nao_tem_acesso():
    assert not tem_acesso(tem_assinatura_ativa=False, xp_total=18_000, limiar_gratis=18_000)
    assert not tem_acesso(tem_assinatura_ativa=False, xp_total=50_000, limiar_gratis=18_000)


def test_sem_trilha_semeada_nao_trava_ninguem():
    """`limiar_gratis=None` (catálogo não semeado) não é motivo pra bloquear —
    o gate de assinatura não é o lugar pra acusar ambiente mal configurado."""
    assert tem_acesso(tem_assinatura_ativa=False, xp_total=999_999, limiar_gratis=None)


def test_status_de_eventos_que_concedem_acesso():
    for tipo in ("INITIAL_PURCHASE", "RENEWAL", "UNCANCELLATION", "PRODUCT_CHANGE"):
        assert status_de(tipo) == "ativa"


def test_status_de_billing_issue_vira_periodo_de_graca():
    assert status_de("BILLING_ISSUE") == "em_periodo_de_graca"


def test_status_de_expiration_vira_expirada():
    assert status_de("EXPIRATION") == "expirada"


def test_status_de_refund_vira_reembolsada():
    assert status_de("REFUND") == "reembolsada"


def test_status_de_cancellation_nao_muda_o_status():
    """CANCELLATION só desliga a renovação automática — o acesso continua até
    `expira_em`; só a EXPIRATION de fato (evento futuro) expira de verdade."""
    assert status_de("CANCELLATION") is None


def test_status_de_tipo_desconhecido_nao_muda_o_status():
    assert status_de("ALGO_NOVO_QUE_A_APPLE_INVENTOU") is None
