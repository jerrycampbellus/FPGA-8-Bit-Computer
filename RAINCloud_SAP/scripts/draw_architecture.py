# RAINCloud Digital | RAINCloud_SAP
# Original SAP design and codebase: J. Campbell.
#
"""Generate the editable architecture SVGs using Python's standard library.

Run from any directory: python scripts/draw_architecture.py
SVG coordinates intentionally preserve a readable engineering layout.
PNG previews are exports of these SVGs, not an independent diagram source.
"""
from pathlib import Path
from html import escape

OUT = Path(__file__).resolve().parents[1] / 'docs/images'
INK = '#17304a'
MUTED = '#52677c'
TEAL = '#087f8c'
VIOLET = '#6d58a5'
AMBER = '#ac620e'
BLUE = '#326fa8'


class Diagram:
    def __init__(self, width, height, title, description):
        self.width, self.height = width, height
        self.items = [f'''<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img" aria-labelledby="title desc">
<title id="title">{escape(title)}</title><desc id="desc">{escape(description)}</desc>
<defs>''']
        for name, color in [('data', TEAL), ('clock', VIOLET), ('control', AMBER), ('view', BLUE)]:
            self.items.append(f'<marker id="{name}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z" fill="{color}"/></marker>')
        self.items.append('</defs>')
        self.rect(0, 0, width, height, '#f5f8fc', radius=0)

    def rect(self, x, y, w, h, fill, stroke='none', radius=14):
        self.items.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{radius}" fill="{fill}" stroke="{stroke}" stroke-width="1.5"/>')

    def text(self, x, y, value, size=20, color=INK, weight=400, anchor='start'):
        self.items.append(f'<text x="{x}" y="{y}" font-family="Segoe UI, DejaVu Sans, sans-serif" font-size="{size}" font-weight="{weight}" text-anchor="{anchor}" fill="{color}">{escape(value)}</text>')

    def vertical_label(self, line_x, y, value, size=17, color=TEAL, side='right'):
        # Keep text beside the connector, with a consistent 18-pixel clearance.
        offset, anchor = (-18, 'end') if side == 'left' else (18, 'start')
        self.text(line_x + offset, y, value, size=size, color=color, anchor=anchor)

    def path(self, coordinates, kind='data', both=False, arrow=True, dashed=False, width=3):
        color = {'data': TEAL, 'clock': VIOLET, 'control': AMBER, 'view': BLUE}[kind]
        extra = f' marker-end="url(#{kind})"' if arrow else ''
        if both:
            extra += f' marker-start="url(#{kind})"'
        if dashed:
            extra += ' stroke-dasharray="8 6"'
        self.items.append(f'<path d="{coordinates}" fill="none" stroke="{color}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"{extra}/>')

    def card(self, x, y, w, h, title, lines, accent=TEAL, size=21):
        self.rect(x, y, w, h, '#ffffff', '#cedbe6')
        self.rect(x + 1, y + 17, 4, h - 34, accent, radius=2)
        self.text(x + 20, y + 35, title, size=size, weight=650)
        for n, line in enumerate(lines):
            self.text(x + 20, y + 64 + n * 25, line, size=17, color=MUTED)

    def header(self, title, subtitle, badge):
        self.rect(0, 0, self.width, 150, '#10263e', radius=0)
        self.text(42, 36, 'RAINCloud Digital  /  J. Campbell', 18, '#86d6db', 600)
        self.text(42, 84, title, 38, '#ffffff', 650)
        self.text(42, 119, subtitle, 19, '#c8d7e8')
        self.text(self.width - 42, 37, badge, 16, '#c8d7e8', anchor='end')

    def save(self, name):
        OUT.mkdir(parents=True, exist_ok=True)
        (OUT / name).write_text('\n'.join(self.items) + '\n</svg>\n', encoding='utf-8')


def overview():
    d = Diagram(1440, 960, 'RAINCloud SAP system overview',
                'DE10-Lite inputs pass through input conditioning into the SAP CPU. '
                'A 50 MHz clock drives the clock generator and input conditioner. '
                'Clock and microcode control the eight-bit datapath; state and output '
                'are routed to the diagnostic display. Reset and mode routes are grouped.')
    d.header('An 8-bit computer, one module at a time',
             'RAINCloud_SAP  •  Structural Verilog  •  Terasic DE10-Lite / MAX 10', 'SYSTEM OVERVIEW')
    d.text(42, 193, '8-bit datapath', 20, weight=600)
    d.text(285, 193, '16 × 8 program / data RAM', 20, weight=600)
    d.text(665, 193, 'T0–T4 microcode sequence', 20, weight=600)
    d.rect(575, 225, 580, 615, '#eaf1f8', '#c0d1e0', 20)
    d.text(599, 254, 'BE_8_BIT_Computer', 21, weight=650)

    # Connector routes precede cards so the node edges remain clean.
    d.path('M 260 325 H 600', 'clock', dashed=True)
    d.path('M 405 325 V 470', 'clock', dashed=True)
    d.text(329, 307, '50 MHz', 18, VIOLET)
    d.path('M 260 550 H 300', 'control')
    d.path('M 530 550 H 575', 'control')
    d.path('M 830 325 H 875', 'clock', dashed=True)
    d.path('M 710 380 V 495', 'clock', dashed=True)
    d.vertical_label(710, 432, 'CPU clock', 18, VIOLET)
    d.path('M 978 380 V 495', 'control')
    d.vertical_label(978, 432, 'enables', 18, AMBER, side='left')
    d.path('M 1105 495 V 380', 'control')
    d.vertical_label(1105, 438, 'opcode /', 16, AMBER, side='left')
    d.vertical_label(1105, 462, 'flags', 16, AMBER, side='left')
    d.path('M 865 645 V 710', 'view')
    d.vertical_label(865, 683, 'state / OUT / bus sample', 17, BLUE)
    d.path('M 1130 752 H 1200', 'view')
    d.path('M 1155 325 H 1200', 'control')

    d.card(40, 275, 220, 100, 'Board oscillator', ['MAX10_CLK1_50'], VIOLET)
    d.card(40, 470, 220, 160, 'Keys + switches',
           ['KEY0: reset', 'KEY1: manual step', 'SW: mode / display'], AMBER)
    d.card(300, 470, 230, 160, 'input_conditioner',
           ['Synchronize inputs', 'Debounce manual step', 'Condition reset'], AMBER, size=19)
    d.text(301, 669, 'reset · step · switches', 17, AMBER)
    d.text(301, 694, 'Grouped routes into CPU', 16, MUTED)
    d.card(600, 275, 230, 105, 'BE_Clock', ['Auto / manual phases', 'Independent display tick'], VIOLET)
    d.card(875, 275, 255, 105, 'Control_Logic', ['MicroCode_StateMachine', 'Sequence T0 → T4'], AMBER)
    d.card(600, 495, 530, 150, '8-bit datapath + shared data_bus',
           ['PC · MAR · RAM · instruction register',
            'A / B registers → ALU + retained flags',
            'Output register · Bus_Display_Register'], TEAL, size=23)
    d.card(600, 710, 530, 100, 'JC_Display',
           ['Select and decode register, memory, control, or OUT state'], BLUE)
    d.card(1200, 275, 200, 125, 'Status LEDs',
           ['LEDR0: CPU clock', 'LEDR9: HALT'], AMBER, size=20)
    d.card(1200, 710, 200, 125, 'Visible output',
           ['HEX0–HEX5', 'LEDR8:1'], BLUE, size=20)

    d.text(42, 735, 'Registered state', 20, weight=650)
    d.text(42, 767, 'rising CPU edge → datapath', 18, MUTED)
    d.text(42, 797, 'falling CPU edge → microstep', 18, MUTED)
    d.rect(40, 864, 1360, 65, '#ffffff', '#d5e0e9', 13)
    d.path('M 62 894 H 99', 'clock', dashed=True)
    d.text(111, 901, 'Clock', 17, MUTED)
    d.path('M 230 894 H 267', 'control')
    d.text(279, 901, 'Control / status', 17, MUTED)
    d.path('M 480 894 H 517', 'view')
    d.text(529, 901, 'Display / observation', 17, MUTED)
    d.text(1369, 901, 'HALT stops CPU activity; display inspection continues.', 17, INK, anchor='end')
    d.save('sap-overview.svg')


def datapath():
    d = Diagram(1500, 1030, 'RAINCloud SAP CPU datapath',
                'Six gated source buses feed data_bus. Program counter, RAM, '
                'instruction register, A and B registers have separate read and load paths. '
                'MAR supplies the four-bit RAM address. A and B feed the ALU directly. '
                'The bus loads MAR, output register, and the display sampler. '
                'Clock/reset/control and diagnostic taps are grouped in the system overview.')
    d.header('Inside the SAP datapath',
             'Actual module boundaries and signal directions  •  See ARCHITECTURE.md for control timing', 'CPU DATA ROUTES')

    # Dedicated operand and address paths run outside the shared-bus area.
    d.path('M 970 250 V 185 H 1400 V 722 H 1285')
    d.text(1190, 176, 'a_value[7:0]', 18, TEAL)
    d.path('M 1360 305 H 1440 V 765 H 1285')
    d.text(1300, 750, 'b_value[7:0]', 18, TEAL)
    d.path('M 60 735 H 30 V 212 H 440 V 250')
    d.text(62, 203, 'ram_address[3:0]  •  dedicated address path', 18, TEAL)

    # Each double arrow describes both the gated output and the distinct load.
    for x, label, output_description, load_description in [
        (170, 'pc_bus[7:0]', 'PC → bus', 'bus[3:0] → PC (jump)'),
        (440, 'ram_bus[7:0]', 'RAM read → bus', 'bus → RAM write'),
        (710, 'instruction_bus[7:0]', 'Operand → bus', 'bus → instruction'),
        (980, 'a_bus[7:0]', 'A → bus', 'bus → A'),
        (1250, 'b_bus[7:0]*', 'B → bus*', 'bus → B'),
    ]:
        d.path(f'M {x} 380 V 465', both=True)
        d.vertical_label(x, 405, label)
        d.vertical_label(x, 429, output_description, 16)
        d.vertical_label(x, 453, load_description, 16)

    d.rect(60, 465, 1300, 80, '#d5eff0', '#6bbac1', 13)
    d.text(91, 499, 'data_bus[7:0]', 25, TEAL, 700)
    d.text(91, 525, 'One selected source; disabled sources and idle bus = 0', 18, INK)
    d.text(1329, 514, 'ALU | A | B | instruction operand | PC | RAM', 19, INK, anchor='end')
    for x, label, description in [
        (170, 'data_bus[3:0]', 'Load RAM address'),
        (495, 'data_bus[7:0]', 'Capture OUT byte'),
        (788, 'data_bus[7:0]', 'Sample bus for display'),
    ]:
        d.path(f'M {x} 545 V 660')
        d.vertical_label(x, 590, label)
        d.vertical_label(x, 615, description, 16)
    d.path('M 1115 660 V 545')
    d.vertical_label(1115, 590, 'alu_bus[7:0]')
    d.vertical_label(1115, 615, 'ADD / SUB result → bus', 16)

    d.card(60, 250, 220, 130, 'Program_Counter', ['4-bit PC; wraps at 16', 'Count / jump load'], size=20)
    d.card(330, 250, 220, 130, 'RAM', ['16 × 8 shared memory', 'Instructions + data'], size=23)
    d.card(600, 250, 220, 130, 'Instruction_Register', ['8-bit instruction', 'Opcode + operand'], size=18)
    d.card(870, 250, 220, 130, 'A_Register', ['8-bit accumulator', 'ALU operand A'], size=22)
    d.card(1140, 250, 220, 130, 'B_Register', ['8-bit temporary value', 'ALU operand B'], size=22)
    d.card(60, 660, 220, 150, 'MAR', ['Memory address register', 'Capture low bus nibble', 'Supply RAM address'], size=23)
    d.card(370, 660, 250, 150, 'Output_Register', ['Capture 8-bit OUT value', 'Signed / unsigned', 'Decimal / hexadecimal'], size=21)
    d.card(650, 660, 275, 150, 'Bus_Display_Register', ['8-bit diagnostic register', 'Samples on CPU rise', 'Feeds JC_Display'], BLUE, size=21)
    d.card(955, 660, 330, 150, 'ALU + retained flags', ['8-bit ADD / SUB', 'Zero + carry / borrow', 'Flags captured with writeback'], size=23)

    d.text(60, 866, 'Reading this diagram', 22, weight=650)
    d.text(60, 901, 'Double arrows denote separate output-enable and load paths, not physical internal tri-state drivers.', 19, MUTED)
    d.text(60, 932, 'PC and instruction outputs are zero-extended to 8 bits. *B output exists but is unused by current microcode.', 19, MUTED)
    d.text(60, 963, 'Control, clock, reset, and JC_Display observation taps are documented separately to keep the datapath readable.', 19, MUTED)
    d.text(60, 1005, 'RAINCloud Digital  •  Original SAP design and codebase: J. Campbell', 16, MUTED)
    d.save('sap-datapath.svg')


if __name__ == '__main__':
    overview()
    datapath()
    print(f'Generated two architecture SVGs in {OUT}')
