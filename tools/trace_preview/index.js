'use strict';


/**
  * Uses canvas.measureText to compute and return the width of the given text of given font in pixels.
  * 
  * @param {String} text The text to be rendered.
  * @param {String} font The css font descriptor that text is to be rendered with (e.g. "bold 14px verdana").
  * 
  * @see https://stackoverflow.com/questions/118241/calculate-text-width-with-javascript/21015393#21015393
  */
function getTextWidth(text, font) {
	// re-use canvas object for better performance
	const canvas = getTextWidth.canvas || (getTextWidth.canvas = document.createElement("canvas"));
	const context = canvas.getContext("2d");
	context.font = font;
	const metrics = context.measureText(text);
	return metrics.width;
}


function set_status(text) {
	$("#status-a").text(text);
}
function get_status() {
	return $("#status-a").text();
}

const SOURCE_FILE_PATH = "/test_local/test_input.sel";
const TRACE_FILE_PATH = "/test_local/test.relabel_trace";

var source_editor;
var trace_editor;

class TraceInfo {
	/** @type string */
	name;
	/** @type integer */
	start;
	/** @type integer */
	finish;
	/** @type boolean */
	failed;
	/** @type TraceInfo[] */
	traces;

	constructor(name, start) {
		this.name = name;
		this.start = start;
		this.finish = start;
		this.failed = false;
		this.traces = [];
	}
}
/** @type TraceInfo */
let trace = new TraceInfo("ROOT", 0);
function update_trace() {
	console.log("update_trace()");
	set_status("Processing trace...");

	/** @type string[] */
	let lines = trace_editor.getValue().split("\n");

	trace = new TraceInfo("ROOT", 0);
	/** @type TraceInfo[] */
	let trace_path = [trace];

	lines.forEach(line => {
		let parts = /([┌│└]+)(check|good|failed) match at (\d+) : (.*)/.exec(line);
		if (parts == null) return;
		let [_1, _2, status, pos, name] = parts;
		pos = Number.parseInt(pos)-1;
		if (status === "check") {
			let trace = new TraceInfo(name, pos);
			trace_path[trace_path.length-1].traces.push(trace);
			trace_path.push(trace)
		} else {
			trace_path[trace_path.length-1].finish = pos;
			trace_path[trace_path.length-1].failed = status !== "good";
			trace_path.pop();
		}
	});
	// console.log(trace);

	setTimeout(update_trace_preview, 1);
}

const TRACE_NODE_FONT_MAIN = "16px sans-serif";
const TRACE_NODE_FONT_MAIN_SIZE_PX = 16;
const TRACE_NODE_FONT_SUB = "14px sans-serif";
const TRACE_NODE_FONT_SUB_SIZE_PX = 14;
function update_trace_preview() {
	console.log("update_trace_preview()");
	set_status("Generating preview...");

	/** @type {string} */
	const source = source_editor.getValue();
	/**
	 * @param {integer} start 
	 * @param {integer} finish 
	 * @param {integer|undefined} max_width 
	 */
	function get_src_readable(start, finish, max_width) {
		if (max_width == undefined) max_width = 16;
		let source_str;
		if (start === finish) {
			source_str = `'${source.substring(start, start+1)}' @ ${start}`
		} else {
			source_str = source.substring(start, finish);
			if (source_str.length > max_width+4) {
				source_str = source_str.substring(0, max_width) + " ...";
			}
		}
		return source_str;
	}

	const root = d3.hierarchy(trace, t => t.traces);
	/** @type {import("d3-flextree").FlextreeLayout<TraceInfo>} */
	const layout = d3.flextree();
	layout.nodeSize(e => [Math.max(getTextWidth(e.data.name, TRACE_NODE_FONT_MAIN), getTextWidth(get_src_readable(e.data.start, e.data.finish), TRACE_NODE_FONT_SUB)), TRACE_NODE_FONT_MAIN_SIZE_PX+TRACE_NODE_FONT_SUB_SIZE_PX+50]);
	layout.spacing(50);

	const holder = d3.select("#trace-tree");
	holder.selectChildren().remove();

	let sticky_tooltip = false;
	const tooltip = holder.append("div")
		.style("position", "absolute")
		.style("top", 0)
		.style("left", 0)
		.style("width", "max-content")
		.style("height", "max-content")
		.style("transform", "translateX(-50%) translateY(-100%)")
		.style("z-index", 1)
		.style("visibility", "hidden")
		.style("border-width", "2px")
		.style("border-radius", "3px")
		.style("padding", "5px")
		.style("background-color", "#333333AA")
		.text("NO_SOURCE");

	const svg = holder.append("svg")
		.attr("style", `max-width: 100%; height: 100%; font: ${TRACE_NODE_FONT_MAIN};`);

	function svg_update_size() {
		let svg_elem = svg.node();
		let bbox = svg_elem.getBBox();
		let width = Math.max(bbox.width, window.innerWidth);
		let height = Math.max(bbox.height, window.innerHeight);
		svg_elem.setAttribute("width", width);
		svg_elem.setAttribute("height", height);
		svg_elem.setAttribute("viewBox", `${bbox.x} ${bbox.y} ${width} ${height}`);
	}

	const gNode = svg.append("g")
		.attr("cursor", "pointer")
		.attr("pointer-events", "all")
		.attr("stroke-linejoin", "round")
		.attr("stroke-width", 3);

	const gLink = svg.append("g")
		.attr("fill", "none")
		.attr("stroke", "#888")
		.attr("stroke-opacity", 0.4)
		.attr("stroke-width", 1.5);

	let link_def = d3.linkVertical()
		.x(e => e.x)
		.y(e => e.y)

	/**
	 * @param {d3.HierarchyNode<TraceInfo>} parent 
	 */
	function update(parent) {
		layout(root);
		
		let nodes = root.descendants();
		let links = root.links();

		const node = gNode.selectAll("g")
			.data(nodes, e => e.id);

		const nodeEnter = node.enter().append("g");
		const nodeUpdate = node.merge(nodeEnter);
		const nodeExit = node.exit().remove();

		nodeEnter
			.append("circle")
				.attr("fill", e => e.data.failed ? "darkred" : "greenyellow")
				.attr("r", 5);

		nodeEnter
			.append("text")
				.attr("dy", -TRACE_NODE_FONT_MAIN_SIZE_PX - TRACE_NODE_FONT_SUB_SIZE_PX)
				.attr("x", e => -getTextWidth(e.data.name, TRACE_NODE_FONT_MAIN)/2)
				.text(e => e.data.name)
				.attr("fill", "#EEE");

		nodeEnter
			.append("text")
				.attr("dy", -TRACE_NODE_FONT_SUB_SIZE_PX)
				.attr("x", e => -getTextWidth(get_src_readable(e.data.start, e.data.finish), TRACE_NODE_FONT_SUB)/2)
				.text(e => get_src_readable(e.data.start, e.data.finish))
				.attr("fill", "#AAA");
		
		nodeEnter
			.each(function(e) {
				if (e._children.length <= 0) {
					d3.select(this)
						.append("line")
							.attr("x1", -8)
							.attr("x2", 8)
							.attr("y1", 5)
							.attr("y2", 5)
							.attr("stroke", "#008")
							.attr("stroke-width", 5);
				}
			})

		nodeEnter
			.on("click", (event, e) => {
				if (event.shiftKey) {
					sticky_tooltip = !sticky_tooltip;
				} else if (e._children.length > 0) {
					if (e.children !== null) {
						e.children = null;
					} else {
						e.children = e._children;
					}
					update(e);
				}
			})
			.on("mouseover", (event, e) => {
				tooltip.style("visibility", "visible");
				tooltip.text(get_src_readable(e.data.start, e.data.finish, 128));
			})
			.on("mousemove", (event, e) => {
				const [mx, my] = d3.pointer(event, e);
				const [lmx, lmy] = d3.pointer(event);
				const [tx, ty] = [mx - lmx, my - lmy];
				tooltip.style("top", `${ty-TRACE_NODE_FONT_MAIN_SIZE_PX*2}px`).style("left", `${tx}px`);
			})
			.on("mouseout", (event, e) => {
				if (!sticky_tooltip) {
					tooltip.style("visibility", "hidden")
				}
			})

		nodeEnter
			.attr("transform", e => `translate(${e.x},${e.y})`);
		
		nodeUpdate
			.attr("transform", e => `translate(${e.x},${e.y})`);

		const link = gLink.selectAll("path")
			.data(links, e => e.target.id);
		
		const linkEnter = link.enter().append("path");
		const linkUpdate = link.merge(linkEnter);
		const linkExit = link.exit().remove();

		linkEnter
			.attr("d", link_def);
		
		linkUpdate
			.attr("d", link_def);

		setTimeout(svg_update_size(), 0);
	}

	root.descendants().forEach((e, i) => {
		e.id = i;
		e._children = e.children;
		if (e._children == undefined) e._children = [];
		if (e.data.failed) e.children = null;
	});

	update(root);

	set_status("Finished.");
}

$(() => {
	source_editor = ace.edit("source");
	source_editor.setTheme("ace/theme/twilight");
	source_editor.session.setMode("ace/mode/lua");
	source_editor.setShowPrintMargin(false);
	source_editor.session.on("change", function(delta) {
		// delta.start, delta.end, delta.lines, delta.action
		setTimeout(update_trace_preview, 1);
	});
	// source_editor.session.selection.on("changeCursor", function(e) {
	// 	let pos = source_editor.session.doc.positionToIndex(source_editor.selection.getCursor());
	// 	update_trace_preview();
	// });

	trace_editor = ace.edit("trace");
	trace_editor.setTheme(source_editor.getTheme());
	trace_editor.session.setMode("ace/mode/logiql");
	trace_editor.setShowPrintMargin(false);
	trace_editor.session.on("change", function(delta) {
		// delta.start, delta.end, delta.lines, delta.action
		setTimeout(update_trace, 1);
	});

	function fetch_stuff() {
		fetch(SOURCE_FILE_PATH)
			.then((res) => res.text())
			.then((text) => {
				if (text !== source_editor.getValue()){
					source_editor.setValue(text);
				}
			})
			.catch((e) => console.error(e));
		fetch(TRACE_FILE_PATH)
			.then((res) => res.text())
			.then((text) => {
				if (text !== trace_editor.getValue()) {
					trace_editor.setValue(text);
				}
			})
			.catch((e) => console.error(e));
	}

	fetch_stuff();
	setInterval(fetch_stuff, 3000);
});