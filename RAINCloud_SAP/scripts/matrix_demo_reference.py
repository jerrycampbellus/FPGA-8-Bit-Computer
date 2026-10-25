# RAINCloud Digital | RAINCloud_SAP
# Original SAP design and codebase: J. Campbell (Jerry Campbell).
"""Exact integer oracle and SDRAM payloads for the proposed matrix demo.

No FPGA, JTAG or SDRAM access. Python integers avoid intermediate overflow.
Run with --self-test, or --output build/ai_edge/reference_vectors.json.
"""
import argparse
import json
import random
from pathlib import Path


def shape(matrix, bits):
    if not isinstance(matrix, list) or not matrix or not isinstance(matrix[0], list):
        raise ValueError('Expected a nonempty rectangular matrix')
    rows, cols = len(matrix), len(matrix[0])
    if not 1 <= rows <= 16 or not 1 <= cols <= 16:
        raise ValueError('Reference dimensions must be 1..16')
    for row in matrix:
        if not isinstance(row, list) or len(row) != cols:
            raise ValueError('Ragged matrix')
        if any(type(x) is not int or not -(1 << (bits-1)) <= x < (1 << (bits-1)) for x in row):
            raise ValueError(f'Expected signed {bits}-bit integers')
    return rows, cols


def matmul_add(a, b, d):
    m, k = shape(a, 8)
    bk, n = shape(b, 8)
    if bk != k or shape(d, 16) != (m, n):
        raise ValueError('Incompatible A, B and D dimensions')
    y = [[sum(a[i][t] * b[t][j] for t in range(k)) + d[i][j]
          for j in range(n)] for i in range(m)]
    shape(y, 32)  # This bounded profile must fit without wrapping or saturation.
    return y


def payload(matrix, bits):
    shape(matrix, bits)
    return b''.join(x.to_bytes(bits // 8, 'little', signed=True)
                    for row in matrix for x in row)


def case(name, a, b, d):
    y = matmul_add(a, b, d)
    return {'name': name, 'A': a, 'B': b, 'D': d, 'Y': y,
            'payload_hex': {key: payload(value, bits).hex()
                            for key, value, bits in [('A', a, 8), ('B', b, 8),
                                                     ('D', d, 16), ('Y', y, 32)]}}


def vectors():
    def filled(value):
        return [[value] * 4 for _ in range(4)]
    identity = [[int(i == j) for j in range(4)] for i in range(4)]
    ramp = [[4 * i + j - 8 for j in range(4)] for i in range(4)]
    zero = filled(0)
    directed = [
        case('zero', zero, zero, zero),
        case('identity', ramp, identity, zero),
        case('add_only', zero, ramp, ramp),
        case('identity_plus_D', ramp, identity, ramp),
        case('positive_extreme', filled(-128), filled(-128), filled(32767)),
        case('negative_extreme', filled(-128), filled(127), filled(-32768)),
        case('mixed_sign', ramp, list(reversed(ramp)), filled(-1)),
    ]
    rng = random.Random(0x5A9)
    def random_matrix(lo, hi):
        return [[rng.randint(lo, hi) for _ in range(4)] for _ in range(4)]
    return directed + [case(f'random_{i:03}', random_matrix(-128, 127),
                            random_matrix(-128, 127), random_matrix(-32768, 32767))
                       for i in range(100)]


def self_test():
    assert matmul_add([[1, -2], [3, 4]], [[5, 6], [-7, 8]],
                      [[9, 10], [-11, 12]]) == [[28, 0], [-24, 62]]
    cases = vectors()
    assert len(cases) == 107
    assert cases[1]['Y'] == cases[1]['A']
    assert cases[2]['Y'] == cases[2]['D']
    assert cases[3]['Y'] == [[2*x for x in row] for row in cases[3]['A']]
    assert cases[4]['Y'] == [[98303]*4 for _ in range(4)]
    assert cases[5]['Y'] == [[-97792]*4 for _ in range(4)]
    assert payload([[-128, 127]], 8) == bytes.fromhex('807f')
    assert payload([[-32768, 32767]], 16) == bytes.fromhex('0080ff7f')
    assert payload([[-1, 98303]], 32) == bytes.fromhex('ff ff ff ff ff 7f 01 00')
    for c in cases:
        assert [len(bytes.fromhex(c['payload_hex'][key])) for key in 'ABDY'] == [16, 16, 32, 64]
    try:
        matmul_add([[128]], [[1]], [[0]])
    except ValueError:
        pass
    else:
        raise AssertionError('Out-of-range input accepted')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--self-test', action='store_true')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    if args.self_test:
        self_test()
        print('PASS software reference: known answers, extrema, packing; 107 vectors')
    if args.output or not args.self_test:
        data = {'status': 'Proposed teaching profile; software results only',
                'operation': 'Y = A @ B + D', 'seed': 0x5A9,
                'layout': 'row-major, little-endian; A/B int8, D int16, Y int32',
                'sdram_byte_bases': {'A': 0x1000, 'B': 0x1800, 'D': 0x2000, 'Y': 0x2800},
                'cases': vectors()}
        encoded = json.dumps(data, indent=2) + '\n'
        if args.output:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(encoded, encoding='utf-8')
            print(f'Wrote {len(data["cases"])} software reference vectors to {args.output}')
        else:
            print(encoded, end='')


if __name__ == '__main__':
    main()
