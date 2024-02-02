import can
from flojoy import Stateful

def test_FILTER_CAN_BY_ERROR(mock_flojoy_decorator):
    import FILTER_CAN_BY_ERROR

    will_remain = can.Message(arbitration_id=2, data=[1, 2, 3, 4], is_extended_id=False, is_error_frame=True)
    messages = [
        can.Message(arbitration_id=1, data=[1, 2, 3, 4], is_extended_id=False),
        will_remain,
        can.Message(arbitration_id=3, data=[1, 2, 3, 4], is_extended_id=False),
    ]

    res = FILTER_CAN_BY_ERROR.FILTER_CAN_BY_ERROR(Stateful(messages))

    assert len(res.obj) == 1
    assert res.obj[0] == will_remain
