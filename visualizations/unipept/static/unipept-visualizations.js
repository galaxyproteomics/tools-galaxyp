/*jshint -W079 */
let univis = univis || {};

univis.Node = class Node {
    constructor(node = {}) {
        this.data = {};
        Object.assign(this, node);
    }

    static new(node = {}) {
        return new Node(node);
    }

    static createNode(node, construct = Node.new) {
        if (node.children) {
            node.children = node.children.map(n => Node.createNode(n, construct));
        }
        return construct.call(null, node);
    }

    // sets a property for a node and all its children
    setRecursiveProperty(property, value) {
        this[property] = value;
        if (this.children) {
            this.children.forEach(c => {
                c.setRecursiveProperty(property, value);
            });
        } else if (this._children) {
            this._children.forEach(c => {
                c.setRecursiveProperty(property, value);
            });
        }
    }

    // Returns true if a node is a leaf
    isLeaf() {
        return (!this.children && !this._children) ||
            (this.children && this.children.length === 0) ||
            (this._children && this._children.length === 0);
    }

    getHeight() {
        if (this._height === undefined) {
            if (this.isLeaf()) {
                this._height = 0;
            } else {
                this._height = d3.max(this.children, c => c.getHeight()) + 1;
            }
        }
        return this._height;
    }

    getDepth() {
        if (this._depth === undefined) {
            if (this.parent === undefined) {
                this._depth = 0;
            } else {
                this._depth = this.parent.getDepth() + 1;
            }
        }
        return this._depth;
    }
};
;/**
 * Interactive treemap
 */
(function () {
    var TreeMap = function TreeMap(element, data, options = {}) {
        let that = {};

        const MARGIN = {
                top: 0,
                right: 0,
                bottom: 0,
                left: 0
            },
            DEFAULTS = {
                height: 300,
                width: 600,

                className: 'unipept-treemap',
                levels: undefined,
                getLevel: d => d.getDepth(),

                countAccessor: d => d.data.self_count,
                rerootCallback: undefined,

                getBreadcrumbTooltip: d => d.name,
                colorRoot: "#104B7D",
                colorLeaf: "#fdffcc",
                colorBreadcrumbs: "#FF8F00",

                labelHeight: 10,
                getLabel: d => d.name,

                enableTooltips: true,
                getTooltip: getTooltip,
                getTooltipTitle: getTooltipTitle,
                getTooltipText: getTooltipText
            };

        let settings;

        let root,
            nodeId = 0,
            current,
            treemapLayout,
            breadcrumbs,
            treemap,
            tooltip,
            colorScale;

        /**
         * Initializes Treemap
         */
        function init() {
            settings = Object.assign({}, DEFAULTS, options);

            root = TreemapNode.createNode(data);

            settings.width = settings.width - MARGIN.right - MARGIN.left;
            settings.height = settings.height - MARGIN.top - MARGIN.bottom;

            settings.levels = settings.levels || root.getHeight();

            if (settings.enableTooltips) {
                initTooltip();
            }

            initCSS();

            // setup the visualisation
            draw(root);
            reroot(root, false);
        }

        function initTooltip() {
            tooltip = d3.select("body")
                .append("div")
                .attr("id", element.id + "-tooltip")
                .attr("class", "tip")
                .style("position", "absolute")
                .style("z-index", "10")
                .style("visibility", "hidden")
                .style("background-color", "white")
                .style("padding", "2px")
                .style("border", "1px solid #dddddd")
                .style("border-radius", "3px;");
        }

        function initCSS() {
            let elementClass = settings.className;
            $(element).addClass(elementClass);
            $("<style>").prop("type", "text/css")
                .html(`
                    .${elementClass} {
                        font-family: Roboto,'Helvetica Neue',Helvetica,Arial,sans-serif;
                    }
                    .${elementClass} .node {
                        font-size: 9px;
                        line-height: 10px;
                        overflow: hidden;
                        position: absolute;
                        text-indent: 2px;
                        text-align: center;
                        text-overflow: ellipsis;
                        cursor: pointer;
                    }
                    .${elementClass} .node:hover {
                        outline: 1px solid white;
                    }
                    .${elementClass} .breadcrumbs {
                        font-size: 11px;
                        line-height: 20px;
                        padding-left: 5px;
                        font-weight: bold;
                        color: white;
                        box-sizing: border-box;
                    }
                    .full-screen .${elementClass} .breadcrumbs {
                        width: 100% !important;
                    }
                    .${elementClass} .crumb {
                        cursor: pointer;
                    }
                    .${elementClass} .crumb .link:hover {
                        text-decoration: underline;
                    }
                    .${elementClass} .breadcrumbs .crumb + .crumb::before {
                        content: " > ";
                        cursor: default;
                    }
                `)
                .appendTo("head");
        }

        function draw(data) {
            $(element).empty();

            treemapLayout = d3.layout.treemap()
                .size([settings.width + 1, settings.height + 1])
                .padding([settings.labelHeight, 0, 0, 0])
                .value(settings.countAccessor);

            colorScale = d3.scale.linear()
                .domain([0, settings.levels])
                .range([settings.colorRoot, settings.colorLeaf])
                .interpolate(d3.interpolateLab);

            breadcrumbs = d3.select(element).append("div")
                .attr("class", "breadcrumbs")
                .style("position", "relative")
                .style("width", settings.width + "px")
                .style("height", "20px")
                .style("background-color", settings.colorBreadcrumbs);

            treemap = d3.select(element).append("div")
                .style("position", "relative")
                .style("width", settings.width + "px")
                .style("height", settings.height + "px")
                .style("left", MARGIN.left + "px")
                .style("top", MARGIN.top + "px");
        }

        function setBreadcrumbs() {
            let crumbs = [];
            let temp = current;
            while (temp) {
                crumbs.push(temp);
                temp = temp.parent;
            }
            crumbs.reverse();
            breadcrumbs.html("");
            breadcrumbs.selectAll(".crumb")
                .data(crumbs)
                .enter()
                .append("span")
                .attr("class", "crumb")
                .attr("title", settings.getBreadcrumbTooltip)
                .html(d => `<span class='link'>${d.name}</span>`)
                .on("click", d => {
                    reroot(d);
                });
        }

        function reroot(data, triggerCallback = true) {
            current = data;

            setBreadcrumbs();

            let nodes = treemap.selectAll(".node")
                .data(treemapLayout.nodes(data), d => d.id || (d.id = ++nodeId));

            nodes.enter()
                .append("div")
                .attr("class", "node")
                .style("background", d => colorScale(settings.getLevel(d)))
                .style("color", d => getReadableColorFor(colorScale(settings.getLevel(d))))
                .style("left", "0px")
                .style("top", "0px")
                .style("width", "0px")
                .style("height", "0px")
                .text(settings.getLabel)
                .on("click", d => {
                    reroot(d);
                })
                .on("contextmenu", d => {
                    d3.event.preventDefault();
                    if (current.parent) {
                        reroot(current.parent);
                    }
                })
                .on("mouseover", tooltipIn)
                .on("mousemove", tooltipMove)
                .on("mouseout", tooltipOut);

            nodes.order()
                .transition()
                .call(position);

            nodes.exit().remove();

            if (triggerCallback && settings.rerootCallback) {
                settings.rerootCallback.call(null, current);
            }
        }

        function update() {
            let nodes = treemap.selectAll(".node")
                .data(treemapLayout.nodes(data), d => d.id)
                .order()
                .transition()
                .call(position);
        }

        /**
         * sets the position of a square
         */
        function position() {
            this.style("left", d => d.x + "px")
                .style("top", d => d.y + "px")
                .style("width", d => Math.max(0, d.dx - 1) + "px")
                .style("height", d => Math.max(0, d.dy - 1) + "px");
        }

        /**
         * Resizes the treemap for a given width and height
         */
        function resize(width, height) {
            treemapLayout = d3.layout.treemap()
                .size([width + 1, height + 1])
                .padding([10, 0, 0, 0])
                .value(settings.countAccessor);
            update();
        }

        // tooltip functions
        function tooltipIn(d, i) {
            if (!settings.enableTooltips) {
                return;
            }
            tooltip.html(settings.getTooltip(d))
                .style("top", (d3.event.pageY - 5) + "px")
                .style("left", (d3.event.pageX + 15) + "px")
                .style("visibility", "visible");
        }

        function tooltipOut(d, i) {
            if (!settings.enableTooltips) {
                return;
            }
            tooltip.style("visibility", "hidden");
        }

        function tooltipMove(d, i) {
            if (!settings.enableTooltips) {
                return;
            }
            tooltip.style("top", (d3.event.pageY - 5) + "px")
                .style("left", (d3.event.pageX + 15) + "px");
        }

        function getTooltip(d) {
            return `<h3 class='tip-title'>${settings.getTooltipTitle(d)}</h3><p>${settings.getTooltipText(d)}</p>`;
        }

        function getTooltipTitle(d) {
            return d.name;
        }

        function getTooltipText(d) {
            return `${d.data.count} hits`;
        }

        /*
         * Returns the readable text color based on the brightness of a given backgroud color
         */
        function getReadableColorFor(color) {
            let textColor = "#000";
            try {
                textColor = brightness(d3.rgb(color)) < 125 ? "#eee" : "#000";
            } catch (err) {}
            return textColor;
        }

        /*
         * Returns the brightness of an rgb-color
         * from: http:// www.w3.org/WAI/ER/WD-AERT/#color-contrast
         */
        function brightness(rgb) {
            return rgb.r * 0.299 + rgb.g * 0.587 + rgb.b * 0.114;
        }

        class TreemapNode extends univis.Node {
            static new(node = {}) {
                return new TreemapNode(node);
            }

            static createNode(node) {
                return univis.Node.createNode(node, TreemapNode.new);
            }
        }


        /*************** Public methods ***************/
        /**
         * Resets the treemap to its initial position
         */
        that.reset = function reset() {
            reroot(root);
        };

        /**
         * Sets the visualisation in full screen mode
         *
         * @param <boolean> isFullScreen indicates if we're in full screen mode
         */
        that.setFullScreen = function setFullScreen(isFullScreen) {
            // the delay is because the event fires before we're in fullscreen
            // so the height en width functions don't give a correct result
            // without the delay
            setTimeout(function () {
                let [w, h] = [settings.width, settings.height];
                if (isFullScreen) {
                    w = $(window).width();
                    h = $(window).height() - 44;
                }
                resize(w, h);
            }, 1000);
        };

        // initialize the object
        init();

        return that;
    };

    function Plugin(userData, option) {
        return this.each(function () {
            let $this = $(this);
            let data = $this.data('vis.treemap');
            let options = $.extend({}, $this.data(), typeof option === 'object' && option);

            if (!data) {
                $this.data('vis.treemap', (data = new TreeMap(this, userData, options)));
            }
            if (typeof option === 'string') {
                data[option]();
            }
        });
    }

    $.fn.treemap = Plugin;
    $.fn.treemap.Constructor = TreeMap;
})();
;/**
 * Zoomable treeview, inspiration from
 * - http://bl.ocks.org/mbostock/4339083
 * - https://gist.github.com/robschmuecker/7880033
 * - http://www.brightpointinc.com/interactive/budget/index.html?source=d3js
 */
(function () {
    var TreeView = function TreeView(element, data, options = {}) {
        let that = {};

        const MARGIN = {
                top: 5,
                right: 5,
                bottom: 5,
                left: 5
            },
            DURATION = 750,
            COLOR_SCALE = d3.scale.category10(),
            DEFAULTS = {
                height: 300,
                width: 600,
                nodeDistance: 180,
                levelsToExpand: 2,
                minNodeSize: 2,
                maxNodeSize: 105,

                countAccessor: d => d.data.count,

                colors: d => COLOR_SCALE(d.name),
                nodeFillColor: nodeFillColor,
                nodeStrokeColor: nodeStrokeColor,
                linkStrokeColor: linkStrokeColor,

                enableInnerArcs: true,
                enableExpandOnClick: true,
                enableRightClick: true,

                enableLabels: true,
                getLabel: d => d.name,

                enableTooltips: true,
                getTooltip: getTooltip,
                getTooltipTitle: getTooltipTitle,
                getTooltipText: getTooltipText
            };

        let settings;

        let visibleRoot,
            tooltipTimer;

        let nodeId = 0,
            root;

        let tree,
            tooltip,
            diagonal,
            widthScale,
            innerArc,
            zoomListener,
            svg;

        function init() {
            settings = Object.assign({}, DEFAULTS, options);

            settings.width = settings.width - MARGIN.right - MARGIN.left;
            settings.height = settings.height - MARGIN.top - MARGIN.bottom;

            if (settings.enableTooltips) {
                initTooltip();
            }

            if (settings.enableInnerArcs) {
                initInnerArcs();
            }

            tree = d3.layout.tree()
                .nodeSize([2, 10])
                .separation((a, b) => {
                    let width = (nodeSize(a) + nodeSize(b)),
                        distance = width / 2 + 4;
                    return (a.parent === b.parent) ? distance : distance + 4;
                });

            diagonal = d3.svg.diagonal().projection(d => [d.y, d.x]);

            widthScale = d3.scale.linear().range([settings.minNodeSize, settings.maxNodeSize]);

            // define the zoomListener which calls the zoom function on the "zoom" event constrained within the scaleExtents
            zoomListener = d3.behavior.zoom()
                .scaleExtent([0.1, 3])
                .on("zoom", () => {
                    svg.attr("transform", `translate(${d3.event.translate})scale(${d3.event.scale})`);
                });

            svg = d3.select(element).append("svg")
                .attr("version", "1.1")
                .attr("xmlns", "http://www.w3.org/2000/svg")
                .attr("viewBox", `0 0 ${settings.width + MARGIN.right + MARGIN.left} ${settings.height + MARGIN.top + MARGIN.bottom}`)
                .attr("width", settings.width + MARGIN.right + MARGIN.left)
                .attr("height", settings.height + MARGIN.top + MARGIN.bottom)
                .call(zoomListener)
                .append("g")
                .attr("transform", `translate(${MARGIN.left},${MARGIN.top})`)
                .append("g");

            draw(TreeviewNode.createNode(data));
        }

        function initTooltip() {
            tooltip = d3.select("body")
                .append("div")
                .attr("id", element.id + "-tooltip")
                .attr("class", "tip")
                .style("position", "absolute")
                .style("z-index", "10")
                .style("visibility", "hidden")
                .style("background-color", "white")
                .style("padding", "2px")
                .style("border", "1px solid #dddddd")
                .style("border-radius", "3px;");
        }

        function initInnerArcs() {
            let arcScale = d3.scale.linear().range([0, 2 * Math.PI]);

            innerArc = d3.svg.arc()
                .outerRadius(nodeSize)
                .startAngle(0)
                .endAngle(d => arcScale(d.data.self_count / d.data.count) || 0);
        }

        function draw(data) {
            widthScale.domain([0, data.data.count]);

            root = data;
            root.x0 = settings.height / 2;
            root.y0 = 0;

            // set everything visible
            root.setSelected(true);

            root.children.forEach((d, i) => {
                d.color = d3.functor(settings.colors).call(this, d, i);
                d.setRecursiveProperty("color", d.color);
            });

            if (settings.enableExpandOnClick) {
                root.collapseAll();
                root.expand();
            } else {
                root.expandAll();
            }

            update(root);
            centerNode(root);
        }

        function update(source) {
            // Compute the new tree layout.
            let nodes = tree.nodes(root).reverse(),
                links = tree.links(nodes);

            // Normalize for fixed-depth.
            nodes.forEach(d => {
                d.y = d.depth * settings.nodeDistance;
            });

            // Update the nodes…
            let node = svg.selectAll("g.node")
                .data(nodes, d => d.id || (d.id = ++nodeId));

            // Enter any new nodes at the parent's previous position.
            let nodeEnter = node.enter().append("g")
                .attr("class", "node")
                .style("cursor", "pointer")
                .attr("transform", d => `translate(${source.y || 0},${source.x0 || 0})`)
                .on("click", click)
                .on("mouseover", tooltipIn)
                .on("mouseout", tooltipOut)
                .on("contextmenu", rightClick);

            nodeEnter.append("circle")
                .attr("r", 1e-6)
                .style("stroke-width", "1.5px")
                .style("stroke", settings.nodeStrokeColor)
                .style("fill", settings.nodeFillColor);

            if (settings.enableInnerArcs) {
                nodeEnter.append("path")
                    .attr("d", innerArc)
                    .style("fill", settings.nodeStrokeColor)
                    .style("fill-opacity", 0);
            }

            if (settings.enableLabels) {
                nodeEnter.append("text")
                    .attr("x", d => d.isLeaf() ? 10 : -10)
                    .attr("dy", ".35em")
                    .attr("text-anchor", d => d.isLeaf() ? "start" : "end")
                    .text(settings.getLabel)
                    .style("font", "10px sans-serif")
                    .style("fill-opacity", 1e-6);
            }

            // Transition nodes to their new position.
            let nodeUpdate = node.transition()
                .duration(DURATION)
                .attr("transform", d => `translate(${d.y},${d.x})`);

            nodeUpdate.select("circle")
                .attr("r", nodeSize)
                .style("fill-opacity", d => d._children ? 1 : 0)
                .style("stroke", settings.nodeStrokeColor)
                .style("fill", settings.nodeFillColor);

            if (settings.enableLabels) {
                nodeUpdate.select("text")
                    .style("fill-opacity", 1);
            }

            if (settings.enableInnerArcs) {
                nodeUpdate.select("path")
                    .duration(DURATION)
                    .attr("d", innerArc)
                    .style("fill-opacity", 0.8);
            }

            // Transition exiting nodes to the parent's new position.
            let nodeExit = node.exit().transition()
                .duration(DURATION)
                .attr("transform", d => `translate(${source.y},${source.x})`)
                .remove();

            nodeExit.select("circle")
                .attr("r", 1e-6);

            nodeExit.select("path")
                .style("fill-opacity", 1e-6);

            nodeExit.select("text")
                .style("fill-opacity", 1e-6);

            // Update the links…
            let link = svg.selectAll("path.link")
                .data(links, d => d.target.id);

            // Enter any new links at the parent's previous position.
            link.enter().insert("path", "g")
                .attr("class", "link")
                .style("fill", "none")
                .style("stroke-opacity", "0.5")
                .style("stroke-linecap", "round")
                .style("stroke", settings.linkStrokeColor)
                .style("stroke-width", 1e-6)
                .attr("d", d => {
                    let o = {
                        x: (source.x0 || 0),
                        y: (source.y0 || 0)
                    };
                    return diagonal({
                        source: o,
                        target: o
                    });
                });

            // Transition links to their new position.
            link.transition()
                .duration(DURATION)
                .attr("d", diagonal)
                .style("stroke", settings.linkStrokeColor)
                .style("stroke-width", d => {
                    if (d.source.selected) {
                        return widthScale(d.target.data.count) + "px";
                    } else {
                        return "4px";
                    }
                });

            // Transition exiting nodes to the parent's new position.
            link.exit().transition()
                .duration(DURATION)
                .style("stroke-width", 1e-6)
                .attr("d", d => {
                    let o = {
                        x: source.x,
                        y: source.y
                    };
                    return diagonal({
                        source: o,
                        target: o
                    });
                })
                .remove();

            // Stash the old positions for transition.
            nodes.forEach(d => {
                [d.x0, d.y0] = [d.x, d.y];
            });
        }

        function nodeSize(d) {
            if (d.selected) {
                return widthScale(d.data.count) / 2;
            } else {
                return 2;
            }
        }

        // Toggle children on click.
        function click(d) {
            if (!settings.enableExpandOnClick) {
                return;
            }

            // check if click is triggered by panning on a node
            if (d3.event.defaultPrevented) {
                return;
            }

            if (d3.event.shiftKey) {
                d.expandAll();
            } else if (d.children) {
                d.collapse();
            } else {
                d.expand();
            }
            update(d);
            centerNode(d);
        }

        function rightClick(d) {
            if (settings.enableRightClick) {
                reroot(d);
            }
        }

        // Sets the width of the right clicked node to 100%
        function reroot(d) {
            if (d === visibleRoot && d !== root) {
                reroot(root);
                return;
            }
            visibleRoot = d;

            // set Selection properties
            root.setSelected(false);
            d.setSelected(true);

            // scale the lines
            widthScale.domain([0, d.data.count]);

            d.expand();

            // redraw
            if (d3.event !== null) {
                d3.event.preventDefault();
            }
            update(d);
            centerNode(d);
        }

        // Center a node
        function centerNode(source) {
            let scale = zoomListener.scale(),
                [x, y] = [-source.y0, -source.x0];
            x = x * scale + settings.width / 4;
            y = y * scale + settings.height / 2;
            svg.transition()
                .duration(DURATION)
                .attr("transform", `translate(${x},${y})scale(${scale})`);
            zoomListener.scale(scale);
            zoomListener.translate([x, y]);
        }

        // tooltip functions
        function tooltipIn(d, i) {
            if (!settings.enableTooltips) {
                return;
            }
            tooltip.html(settings.getTooltip(d))
                .style("top", (d3.event.pageY - 5) + "px")
                .style("left", (d3.event.pageX + 15) + "px");

            tooltipTimer = setTimeout(() => {
                tooltip.style("visibility", "visible");
            }, 1000);

        }

        function tooltipOut(d, i) {
            if (!settings.enableTooltips) {
                return;
            }
            clearTimeout(tooltipTimer);
            tooltip.style("visibility", "hidden");
        }

        /************** Default methods ***************/
        // set fill color
        function nodeFillColor(d) {
            if (d.selected) {
                return d._children ? d.color || "#aaa" : "#fff";
            } else {
                return "#aaa";
            }
        }

        // set node stroke color
        function nodeStrokeColor(d) {
            if (d.selected) {
                return d.color || "#aaa";
            } else {
                return "#aaa";
            }
        }

        // set link stroke color
        function linkStrokeColor(d) {
            if (d.source.selected) {
                return d.target.color;
            } else {
                return "#aaa";
            }
        }

        function getTooltip(d) {
            return `<h3 class='tip-title'>${settings.getTooltipTitle(d)}</h3><p>${settings.getTooltipText(d)}</p>`;
        }

        function getTooltipTitle(d) {
            return d.name;
        }

        function getTooltipText(d) {
            return `${d.data.count} hits`;
        }

        class TreeviewNode extends univis.Node {
            constructor(node = {}) {
                super(node);
                this.setCount();
            }

            static new(node = {}) {
                return new TreeviewNode(node);
            }

            static createNode(node) {
                return univis.Node.createNode(node, TreeviewNode.new);
            }

            setCount() {
                if (settings.countAccessor(this)) {
                    this.data.count = settings.countAccessor(this);
                } else if (this.children) {
                    this.data.count = this.children.reduce((sum, c) => sum + c.data.count, 0);
                } else {
                    this.data.count = 0;
                }
            }

            setSelected(value) {
                this.setRecursiveProperty("selected", value);
            }

            // collapse everything
            collapseAll() {
                if (this.children && this.children.length === 0) {
                    this.children = null;
                }
                if (this.children) {
                    this._children = this.children;
                    this._children.forEach(c => {
                        c.collapseAll();
                    });
                    this.children = null;
                }
            }

            // Collapses a node
            collapse() {
                if (this.children) {
                    this._children = this.children;
                    this.children = null;
                }
            }

            expandAll() {
                this.expand(100);
            }

            // Expands a node and its children
            expand(i = settings.levelsToExpand) {
                if (i > 0) {
                    if (this._children) {
                        this.children = this._children;
                        this._children = null;
                    }
                    if (this.children) {
                        this.children.forEach(c => {
                            c.expand(i - 1);
                        });
                    }
                }
            }
        }

        /*************** Public methods ***************/
        that.reset = function reset() {
            zoomListener.scale(1);
            reroot(root);
        };

        // initialize the object
        init();

        // return the object
        return that;
    };

    function Plugin(userData, option) {
        return this.each(function () {
            let $this = $(this);
            let data = $this.data('vis.treeview');
            let options = $.extend({}, $this.data(), typeof option === 'object' && option);

            if (!data) {
                $this.data('vis.treeview', (data = new TreeView(this, userData, options)));
            }
            if (typeof option === 'string') {
                data[option]();
            }
        });
    }

    $.fn.treeview = Plugin;
    $.fn.treeview.Constructor = TreeView;
})();
