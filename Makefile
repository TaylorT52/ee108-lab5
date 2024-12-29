FILES = src/design/wave_display.v \
	src/design/wave_capture.v \
	src/design/wave_display_top.v \
	src/sim/wave_display_tb.v \
	src/sim/wave_capture_tb.v \
	src/lab5.xdc \
	lab5.runs/impl_1/lab5_top.bit \
	lab5.runs/impl_1/lab5_top_timing_summary_routed.rpt \
	lab5.runs/synth_1/lab5_top.vds

init:
	@vivado -nolog -nojournal -notrace -mode batch -source init_project.tcl
	@echo "Finished initalizing lab. Run vivado on the generated .xpr file to open the project."

submit:
	@rm -f lab5_submission.zip
	@zip -j lab5_submission.zip $(FILES)
	@echo "Generated lab5_submission.zip. If there are any errors, please check if all of your files are in the right places. Congrats on finishing!"
