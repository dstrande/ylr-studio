from .flojoy import flojoy
from .template import init_template

@flojoy
def LINE(node_inputs, params):
    payload = node_inputs[0]

    fig = dict(
        data = [dict(
            x = list(payload['x0']),
            y = list(payload['y0']),
            type='scatter',
            mode='lines'
        )],
        layout = dict(template = init_template())
    )
    return fig