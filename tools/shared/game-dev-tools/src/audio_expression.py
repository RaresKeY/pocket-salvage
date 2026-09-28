"""Validated scalar recipe expressions; no statements, attributes or builtins."""
import ast
import math


def compile_recipe(expression, functions):
    tree = ast.parse(expression, mode='eval')
    nodes = list(ast.walk(tree))
    if len(nodes) > 256:
        raise ValueError('Audio expression exceeds the scalar recipe contract')
    allowed = (ast.Expression, ast.Constant, ast.Name, ast.Load, ast.BinOp, ast.UnaryOp,
               ast.Add, ast.Sub, ast.Mult, ast.Div, ast.Pow, ast.Mod, ast.UAdd, ast.USub,
               ast.IfExp, ast.Compare, ast.Lt, ast.LtE, ast.Gt, ast.GtE, ast.Eq, ast.NotEq,
               ast.List, ast.Tuple, ast.Subscript, ast.Call)
    namespace = {'min': min, 'max': max, 'int': int, 'abs': abs, 'sin': math.sin,
                 'cos': math.cos, 'exp': math.exp, **functions}
    for node in nodes:
        if not isinstance(node, allowed):
            raise ValueError('Unsupported audio expression: ' + type(node).__name__)
        if isinstance(node, ast.Name) and node.id not in {'t', 'p', 'n', *namespace}:
            raise ValueError('Unknown scalar recipe name: ' + node.id)
        if isinstance(node, ast.Call) and (not isinstance(node.func, ast.Name) or node.func.id not in namespace or node.keywords):
            raise ValueError('Only declared scalar recipe calls are permitted')
        if isinstance(node, ast.Constant) and not isinstance(node.value, (int, float, str)):
            raise ValueError('Only scalar numeric and waveform constants are permitted')
    code = compile(tree, '<audio-recipe>', 'eval')
    environment = {'__builtins__': {}, **namespace}
    def sample(t, p, n):
        return eval(code, environment, {'t': t, 'p': p, 'n': n})
    return sample
