<div style="direction: ltr; border-width: 100%;">
<div style="direction: ltr; margin-top: 0in; margin-left: 0in; width: 7.6041in;">
<div style="direction: ltr; margin-top: 0in; margin-left: 0in; width: 7.6041in;">
<h1 style="margin: 0in; font-family: Calibri; font-size: 16.0pt; color: #1e4e79;">FPGA 8 Bit Computer Based on Ben Eater's Discrete Component Design and Implementation</h1>
<p style="margin: 0in; font-family: tahoma; font-size: 11.0pt; color: #0e101a;">&nbsp;</p>
<h2 style="margin: 0in; font-family: Calibri; font-size: 14.0pt; color: #2e75b5;">Background</h2>
<p style="margin: 0in; font-family: tahoma; font-size: 11.0pt; color: #0e101a;">&nbsp;</p>
<p style="margin: 0in; font-family: tahoma; font-size: 11.0pt;"><span style="color: #0e101a;">Like many people who found Ben Eater's 8-bit computer&nbsp;</span><a href="https://www.youtube.com/playlist?list=PLowKtXNTBypGqImE405J2565dvjafglHU">project&nbsp;</a><span style="color: #0e101a;">on YouTube, the series was highly informative and engaging, and it inspired me to take on this project. Ben's approach to building his 8-bit computer and his logical, linear, and realistic style of explaining concepts have motivated many to understand computers and what makes them work. I encourage you to review his&nbsp;</span><a href="https://eater.net/8bit/">website&nbsp;</a><span style="color: #0e101a;">for more information or purchase kits to build the computer.</span></p>
<p style="margin: 0in; font-family: tahoma; font-size: 11.0pt; color: #0e101a;">&nbsp;</p>
<p style="margin: 0in; font-family: tahoma; font-size: 11.0pt; color: #0e101a;">Although I did not build his design using discrete components, I did think there would be value in creating a working implementation with an FPGA, field-programmable gate array. There are several notable examples of using an FPGA to realize full computers or individual components such as the CPU, video card, and I/O devices. This project designs and implements the same elements in Ben's initial design but uses an FPGA development card instead of breadboards and ICs. An exciting challenge and complementary project to the original project.</p>
<p style="margin: 0in; font-family: tahoma; font-size: 11.0pt; color: #0e101a;">&nbsp;</p>
<h2 style="margin: 0in; font-family: Calibri; font-size: 14.0pt; color: #2e75b5;">Goals</h2>
<p style="margin: 0in; font-family: tahoma; font-size: 11.0pt; color: #0e101a;">&nbsp;</p>
<p style="margin: 0in; font-family: tahoma; font-size: 11.0pt; color: #0e101a;">When I considered the goals for my project, I wanted to keep the outcome closely aligned to the outputs from Ben's original project. I wanted to develop an 8-bit Touring complete computer with a limited instruction set as an instructional and, hopefully, an inspirational project for others interested in FPGA design and 8 -bit computer architecture. I wanted to leverage the capability of most FPGA design boards and incorporate inputs and outputs accessible from most manufacturers. Finally, I tried to make the design portable between FPGA manufacturers and development boards, so I built the solution without using softcore intellectual property. All solution elements are written in Verilog and can be customized using an appropriate, manufacture-specific, top-level module to specify a clock, inputs, and outputs. Using these principles, I developed the following list of goals:</p>
<p style="margin: 0in; font-family: tahoma; font-size: 11.0pt; color: #0e101a;">&nbsp;</p>
<ol type="1" style="direction: ltr; unicode-bidi: embed; margin-top: 0in; margin-bottom: 0in; font-family: tahoma; font-size: 11.0pt; font-weight: normal; font-style: normal;">
<li style="margin-top: 0; margin-bottom: 0; vertical-align: middle; color: #0e101a;" value="1"><span style="font-family: tahoma; font-size: 11.0pt; font-weight: normal; font-style: normal;">One-to-one mapping between the original component design and the FPGA design</span></li>
<li style="margin-top: 0; margin-bottom: 0; vertical-align: middle; color: #0e101a;"><span style="font-family: tahoma; font-size: 11.0pt;">Leverage development board-specific clocks, inputs (switches and buttons), and outputs (LEDs and HEX segments)</span></li>
<li style="margin-top: 0; margin-bottom: 0; vertical-align: middle; color: #0e101a;"><span style="font-family: tahoma; font-size: 11.0pt;">Develop all modules using portable Verilog code without the use of Soft IP</span></li>
<li style="margin-top: 0; margin-bottom: 0; vertical-align: middle; color: #0e101a;"><span style="font-family: tahoma; font-size: 11.0pt;">Utilize FPGA design, synthesis, placement and routing, timing analysis, and simulation tools provided by commercial FPGA manufacturers</span></li>
</ol>
<p style="margin: 0in; font-family: tahoma; font-size: 11.0pt; color: #0e101a;">&nbsp;</p>
<p style="margin: 0in; font-family: tahoma; font-size: 11.0pt; color: #0e101a;">The realization approach for each module took one of two paths. Either the module was defined using discrete IC models, or I created a pure Verilog definition. In the former case, I made a schematic file using primary logic gates, and in the latter case, I used design patterns from FPGA reference material. I created the Verilog source code and top-level constraint files for the Terasic FPGA DE10-Lite development board, utilizing a MAX10 FPGA from Alterra. The code repository contains the source files and the project archives from Altera's Quartus Prime software.&nbsp;</p>
<p style="margin: 0in; font-family: tahoma; font-size: 11.0pt; color: #0e101a;">&nbsp;</p>
<h2 style="margin: 0in; font-family: Calibri; font-size: 14.0pt; color: #2e75b5;">Architecture and Approach</h2>
<p></p>
<p>The following represents the components in this project. Each component was developed, unit tested, then integrated to produce the final working system. Each of the components were implemented using either Verilog or built up through schematics entry.</p>
<p><img width="1000" height="563" alt="8-bit Computer Architecture" src="https://user-images.githubusercontent.com/84247829/149634418-664100cb-f746-44d2-aa78-7c0944c4cae2.png" /></p>
<p style="margin: 0in; font-family: Calibri; font-size: 11.0pt;">&nbsp;</p>
</div>
</div>
</div>
