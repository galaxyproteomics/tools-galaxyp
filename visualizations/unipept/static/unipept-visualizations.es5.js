"use strict";

var _typeof = typeof Symbol === "function" && typeof Symbol.iterator === "symbol" ? function (obj) { return typeof obj; } : function (obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol ? "symbol" : typeof obj; };

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

/*jshint -W079 */
var univis = univis || {};

univis.Node = function () {
    function Node() {
        var node = arguments.length <= 0 || arguments[0] === undefined ? {} : arguments[0];

        _classCallCheck(this, Node);

        this.data = {};
        _extends(this, node);
    }

    _createClass(Node, [{
        key: "setRecursiveProperty",


        // sets a property for a node and all its children
        value: function setRecursiveProperty(property, value) {
            this[property] = value;
            if (this.children) {
                this.children.forEach(function (c) {
                    c.setRecursiveProperty(property, value);
                });
            } else if (this._children) {
                this._children.forEach(function (c) {
                    c.setRecursiveProperty(property, value);
                });
            }
        }

        // Returns true if a node is a leaf

    }, {
        key: "isLeaf",
        value: function isLeaf() {
            return !this.children && !this._children || this.children && this.children.length === 0 || this._children && this._children.length === 0;
        }
    }, {
        key: "getHeight",
        value: function getHeight() {
            if (this._height === undefined) {
                if (this.isLeaf()) {
                    this._height = 0;
                } else {
                    this._height = d3.max(this.children, function (c) {
                        return c.getHeight();
                    }) + 1;
                }
            }
            return this._height;
        }
    }, {
        key: "getDepth",
        value: function getDepth() {
            if (this._depth === undefined) {
                if (this.parent === undefined) {
                    this._depth = 0;
                } else {
                    this._depth = this.parent.getDepth() + 1;
                }
            }
            return this._depth;
        }
    }], [{
        key: "new",
        value: function _new() {
            var node = arguments.length <= 0 || arguments[0] === undefined ? {} : arguments[0];

            return new Node(node);
        }
    }, {
        key: "createNode",
        value: function createNode(node) {
            var construct = arguments.length <= 1 || arguments[1] === undefined ? Node.new : arguments[1];

            if (node.children) {
                node.children = node.children.map(function (n) {
                    return Node.createNode(n, construct);
                });
            }
            return construct.call(null, node);
        }
    }]);

    return Node;
}();
; /**
  * Interactive treemap
  */
(function () {
    var TreeMap = function TreeMap(element, data) {
        var options = arguments.length <= 2 || arguments[2] === undefined ? {} : arguments[2];

        var that = {};

        var MARGIN = {
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
            getLevel: function getLevel(d) {
                return d.getDepth();
            },

            countAccessor: function countAccessor(d) {
                return d.data.self_count;
            },
            rerootCallback: undefined,

            getBreadcrumbTooltip: function getBreadcrumbTooltip(d) {
                return d.name;
            },
            colorRoot: "#104B7D",
            colorLeaf: "#fdffcc",
            colorBreadcrumbs: "#FF8F00",

            labelHeight: 10,
            getLabel: function getLabel(d) {
                return d.name;
            },

            enableTooltips: true,
            getTooltip: getTooltip,
            getTooltipTitle: getTooltipTitle,
            getTooltipText: getTooltipText
        };

        var settings = void 0;

        var root = void 0,
            nodeId = 0,
            current = void 0,
            treemapLayout = void 0,
            breadcrumbs = void 0,
            treemap = void 0,
            tooltip = void 0,
            colorScale = void 0;

        /**
         * Initializes Treemap
         */
        function init() {
            settings = _extends({}, DEFAULTS, options);

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
            tooltip = d3.select("body").append("div").attr("id", element.id + "-tooltip").attr("class", "tip").style("position", "absolute").style("z-index", "10").style("visibility", "hidden").style("background-color", "white").style("padding", "2px").style("border", "1px solid #dddddd").style("border-radius", "3px;");
        }

        function initCSS() {
            var elementClass = settings.className;
            $(element).addClass(elementClass);
            $("<style>").prop("type", "text/css").html("\n                    ." + elementClass + " {\n                        font-family: Roboto,'Helvetica Neue',Helvetica,Arial,sans-serif;\n                    }\n                    ." + elementClass + " .node {\n                        font-size: 9px;\n                        line-height: 10px;\n                        overflow: hidden;\n                        position: absolute;\n                        text-indent: 2px;\n                        text-align: center;\n                        text-overflow: ellipsis;\n                        cursor: pointer;\n                    }\n                    ." + elementClass + " .node:hover {\n                        outline: 1px solid white;\n                    }\n                    ." + elementClass + " .breadcrumbs {\n                        font-size: 11px;\n                        line-height: 20px;\n                        padding-left: 5px;\n                        font-weight: bold;\n                        color: white;\n                        box-sizing: border-box;\n                    }\n                    .full-screen ." + elementClass + " .breadcrumbs {\n                        width: 100% !important;\n                    }\n                    ." + elementClass + " .crumb {\n                        cursor: pointer;\n                    }\n                    ." + elementClass + " .crumb .link:hover {\n                        text-decoration: underline;\n                    }\n                    ." + elementClass + " .breadcrumbs .crumb + .crumb::before {\n                        content: \" > \";\n                        cursor: default;\n                    }\n                ").appendTo("head");
        }

        function draw(data) {
            $(element).empty();

            treemapLayout = d3.layout.treemap().size([settings.width + 1, settings.height + 1]).padding([settings.labelHeight, 0, 0, 0]).value(settings.countAccessor);

            colorScale = d3.scale.linear().domain([0, settings.levels]).range([settings.colorRoot, settings.colorLeaf]).interpolate(d3.interpolateLab);

            breadcrumbs = d3.select(element).append("div").attr("class", "breadcrumbs").style("position", "relative").style("width", settings.width + "px").style("height", "20px").style("background-color", settings.colorBreadcrumbs);

            treemap = d3.select(element).append("div").style("position", "relative").style("width", settings.width + "px").style("height", settings.height + "px").style("left", MARGIN.left + "px").style("top", MARGIN.top + "px");
        }

        function setBreadcrumbs() {
            var crumbs = [];
            var temp = current;
            while (temp) {
                crumbs.push(temp);
                temp = temp.parent;
            }
            crumbs.reverse();
            breadcrumbs.html("");
            breadcrumbs.selectAll(".crumb").data(crumbs).enter().append("span").attr("class", "crumb").attr("title", settings.getBreadcrumbTooltip).html(function (d) {
                return "<span class='link'>" + d.name + "</span>";
            }).on("click", function (d) {
                reroot(d);
            });
        }

        function reroot(data) {
            var triggerCallback = arguments.length <= 1 || arguments[1] === undefined ? true : arguments[1];

            current = data;

            setBreadcrumbs();

            var nodes = treemap.selectAll(".node").data(treemapLayout.nodes(data), function (d) {
                return d.id || (d.id = ++nodeId);
            });

            nodes.enter().append("div").attr("class", "node").style("background", function (d) {
                return colorScale(settings.getLevel(d));
            }).style("color", function (d) {
                return getReadableColorFor(colorScale(settings.getLevel(d)));
            }).style("left", "0px").style("top", "0px").style("width", "0px").style("height", "0px").text(settings.getLabel).on("click", function (d) {
                reroot(d);
            }).on("contextmenu", function (d) {
                d3.event.preventDefault();
                if (current.parent) {
                    reroot(current.parent);
                }
            }).on("mouseover", tooltipIn).on("mousemove", tooltipMove).on("mouseout", tooltipOut);

            nodes.order().transition().call(position);

            nodes.exit().remove();

            if (triggerCallback && settings.rerootCallback) {
                settings.rerootCallback.call(null, current);
            }
        }

        function update() {
            var nodes = treemap.selectAll(".node").data(treemapLayout.nodes(data), function (d) {
                return d.id;
            }).order().transition().call(position);
        }

        /**
         * sets the position of a square
         */
        function position() {
            this.style("left", function (d) {
                return d.x + "px";
            }).style("top", function (d) {
                return d.y + "px";
            }).style("width", function (d) {
                return Math.max(0, d.dx - 1) + "px";
            }).style("height", function (d) {
                return Math.max(0, d.dy - 1) + "px";
            });
        }

        /**
         * Resizes the treemap for a given width and height
         */
        function resize(width, height) {
            treemapLayout = d3.layout.treemap().size([width + 1, height + 1]).padding([10, 0, 0, 0]).value(settings.countAccessor);
            update();
        }

        // tooltip functions
        function tooltipIn(d, i) {
            if (!settings.enableTooltips) {
                return;
            }
            tooltip.html(settings.getTooltip(d)).style("top", d3.event.pageY - 5 + "px").style("left", d3.event.pageX + 15 + "px").style("visibility", "visible");
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
            tooltip.style("top", d3.event.pageY - 5 + "px").style("left", d3.event.pageX + 15 + "px");
        }

        function getTooltip(d) {
            return "<h3 class='tip-title'>" + settings.getTooltipTitle(d) + "</h3><p>" + settings.getTooltipText(d) + "</p>";
        }

        function getTooltipTitle(d) {
            return d.name;
        }

        function getTooltipText(d) {
            return d.data.count + " hits";
        }

        /*
         * Returns the readable text color based on the brightness of a given backgroud color
         */
        function getReadableColorFor(color) {
            var textColor = "#000";
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

        var TreemapNode = function (_univis$Node) {
            _inherits(TreemapNode, _univis$Node);

            function TreemapNode() {
                _classCallCheck(this, TreemapNode);

                return _possibleConstructorReturn(this, Object.getPrototypeOf(TreemapNode).apply(this, arguments));
            }

            _createClass(TreemapNode, null, [{
                key: "new",
                value: function _new() {
                    var node = arguments.length <= 0 || arguments[0] === undefined ? {} : arguments[0];

                    return new TreemapNode(node);
                }
            }, {
                key: "createNode",
                value: function createNode(node) {
                    return univis.Node.createNode(node, TreemapNode.new);
                }
            }]);

            return TreemapNode;
        }(univis.Node);

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
                var w = settings.width;
                var h = settings.height;

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
            var $this = $(this);
            var data = $this.data('vis.treemap');
            var options = $.extend({}, $this.data(), (typeof option === "undefined" ? "undefined" : _typeof(option)) === 'object' && option);

            if (!data) {
                $this.data('vis.treemap', data = new TreeMap(this, userData, options));
            }
            if (typeof option === 'string') {
                data[option]();
            }
        });
    }

    $.fn.treemap = Plugin;
    $.fn.treemap.Constructor = TreeMap;
})();
; /**
  * Zoomable treeview, inspiration from
  * - http://bl.ocks.org/mbostock/4339083
  * - https://gist.github.com/robschmuecker/7880033
  * - http://www.brightpointinc.com/interactive/budget/index.html?source=d3js
  */
(function () {
    var TreeView = function TreeView(element, data) {
        var options = arguments.length <= 2 || arguments[2] === undefined ? {} : arguments[2];

        var that = {};

        var MARGIN = {
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

            countAccessor: function countAccessor(d) {
                return d.data.count;
            },

            colors: function colors(d) {
                return COLOR_SCALE(d.name);
            },
            nodeFillColor: nodeFillColor,
            nodeStrokeColor: nodeStrokeColor,
            linkStrokeColor: linkStrokeColor,

            enableInnerArcs: true,
            enableExpandOnClick: true,
            enableRightClick: true,

            enableLabels: true,
            getLabel: function getLabel(d) {
                return d.name;
            },

            enableTooltips: true,
            getTooltip: getTooltip,
            getTooltipTitle: getTooltipTitle,
            getTooltipText: getTooltipText
        };

        var settings = void 0;

        var visibleRoot = void 0,
            tooltipTimer = void 0;

        var nodeId = 0,
            root = void 0;

        var tree = void 0,
            tooltip = void 0,
            diagonal = void 0,
            widthScale = void 0,
            innerArc = void 0,
            zoomListener = void 0,
            svg = void 0;

        function init() {
            settings = _extends({}, DEFAULTS, options);

            settings.width = settings.width - MARGIN.right - MARGIN.left;
            settings.height = settings.height - MARGIN.top - MARGIN.bottom;

            if (settings.enableTooltips) {
                initTooltip();
            }

            if (settings.enableInnerArcs) {
                initInnerArcs();
            }

            tree = d3.layout.tree().nodeSize([2, 10]).separation(function (a, b) {
                var width = nodeSize(a) + nodeSize(b),
                    distance = width / 2 + 4;
                return a.parent === b.parent ? distance : distance + 4;
            });

            diagonal = d3.svg.diagonal().projection(function (d) {
                return [d.y, d.x];
            });

            widthScale = d3.scale.linear().range([settings.minNodeSize, settings.maxNodeSize]);

            // define the zoomListener which calls the zoom function on the "zoom" event constrained within the scaleExtents
            zoomListener = d3.behavior.zoom().scaleExtent([0.1, 3]).on("zoom", function () {
                svg.attr("transform", "translate(" + d3.event.translate + ")scale(" + d3.event.scale + ")");
            });

            svg = d3.select(element).append("svg").attr("version", "1.1").attr("xmlns", "http://www.w3.org/2000/svg").attr("viewBox", "0 0 " + (settings.width + MARGIN.right + MARGIN.left) + " " + (settings.height + MARGIN.top + MARGIN.bottom)).attr("width", settings.width + MARGIN.right + MARGIN.left).attr("height", settings.height + MARGIN.top + MARGIN.bottom).call(zoomListener).append("g").attr("transform", "translate(" + MARGIN.left + "," + MARGIN.top + ")").append("g");

            draw(TreeviewNode.createNode(data));
        }

        function initTooltip() {
            tooltip = d3.select("body").append("div").attr("id", element.id + "-tooltip").attr("class", "tip").style("position", "absolute").style("z-index", "10").style("visibility", "hidden").style("background-color", "white").style("padding", "2px").style("border", "1px solid #dddddd").style("border-radius", "3px;");
        }

        function initInnerArcs() {
            var arcScale = d3.scale.linear().range([0, 2 * Math.PI]);

            innerArc = d3.svg.arc().outerRadius(nodeSize).startAngle(0).endAngle(function (d) {
                return arcScale(d.data.self_count / d.data.count) || 0;
            });
        }

        function draw(data) {
            var _this2 = this;

            widthScale.domain([0, data.data.count]);

            root = data;
            root.x0 = settings.height / 2;
            root.y0 = 0;

            // set everything visible
            root.setSelected(true);

            root.children.forEach(function (d, i) {
                d.color = d3.functor(settings.colors).call(_this2, d, i);
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
            var nodes = tree.nodes(root).reverse(),
                links = tree.links(nodes);

            // Normalize for fixed-depth.
            nodes.forEach(function (d) {
                d.y = d.depth * settings.nodeDistance;
            });

            // Update the nodes…
            var node = svg.selectAll("g.node").data(nodes, function (d) {
                return d.id || (d.id = ++nodeId);
            });

            // Enter any new nodes at the parent's previous position.
            var nodeEnter = node.enter().append("g").attr("class", "node").style("cursor", "pointer").attr("transform", function (d) {
                return "translate(" + (source.y || 0) + "," + (source.x0 || 0) + ")";
            }).on("click", click).on("mouseover", tooltipIn).on("mouseout", tooltipOut).on("contextmenu", rightClick);

            nodeEnter.append("circle").attr("r", 1e-6).style("stroke-width", "1.5px").style("stroke", settings.nodeStrokeColor).style("fill", settings.nodeFillColor);

            if (settings.enableInnerArcs) {
                nodeEnter.append("path").attr("d", innerArc).style("fill", settings.nodeStrokeColor).style("fill-opacity", 0);
            }

            if (settings.enableLabels) {
                nodeEnter.append("text").attr("x", function (d) {
                    return d.isLeaf() ? 10 : -10;
                }).attr("dy", ".35em").attr("text-anchor", function (d) {
                    return d.isLeaf() ? "start" : "end";
                }).text(settings.getLabel).style("font", "10px sans-serif").style("fill-opacity", 1e-6);
            }

            // Transition nodes to their new position.
            var nodeUpdate = node.transition().duration(DURATION).attr("transform", function (d) {
                return "translate(" + d.y + "," + d.x + ")";
            });

            nodeUpdate.select("circle").attr("r", nodeSize).style("fill-opacity", function (d) {
                return d._children ? 1 : 0;
            }).style("stroke", settings.nodeStrokeColor).style("fill", settings.nodeFillColor);

            if (settings.enableLabels) {
                nodeUpdate.select("text").style("fill-opacity", 1);
            }

            if (settings.enableInnerArcs) {
                nodeUpdate.select("path").duration(DURATION).attr("d", innerArc).style("fill-opacity", 0.8);
            }

            // Transition exiting nodes to the parent's new position.
            var nodeExit = node.exit().transition().duration(DURATION).attr("transform", function (d) {
                return "translate(" + source.y + "," + source.x + ")";
            }).remove();

            nodeExit.select("circle").attr("r", 1e-6);

            nodeExit.select("path").style("fill-opacity", 1e-6);

            nodeExit.select("text").style("fill-opacity", 1e-6);

            // Update the links…
            var link = svg.selectAll("path.link").data(links, function (d) {
                return d.target.id;
            });

            // Enter any new links at the parent's previous position.
            link.enter().insert("path", "g").attr("class", "link").style("fill", "none").style("stroke-opacity", "0.5").style("stroke-linecap", "round").style("stroke", settings.linkStrokeColor).style("stroke-width", 1e-6).attr("d", function (d) {
                var o = {
                    x: source.x0 || 0,
                    y: source.y0 || 0
                };
                return diagonal({
                    source: o,
                    target: o
                });
            });

            // Transition links to their new position.
            link.transition().duration(DURATION).attr("d", diagonal).style("stroke", settings.linkStrokeColor).style("stroke-width", function (d) {
                if (d.source.selected) {
                    return widthScale(d.target.data.count) + "px";
                } else {
                    return "4px";
                }
            });

            // Transition exiting nodes to the parent's new position.
            link.exit().transition().duration(DURATION).style("stroke-width", 1e-6).attr("d", function (d) {
                var o = {
                    x: source.x,
                    y: source.y
                };
                return diagonal({
                    source: o,
                    target: o
                });
            }).remove();

            // Stash the old positions for transition.
            nodes.forEach(function (d) {
                var _ref = [d.x, d.y];
                d.x0 = _ref[0];
                d.y0 = _ref[1];
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
            var scale = zoomListener.scale();
            var x = -source.y0;
            var y = -source.x0;

            x = x * scale + settings.width / 4;
            y = y * scale + settings.height / 2;
            svg.transition().duration(DURATION).attr("transform", "translate(" + x + "," + y + ")scale(" + scale + ")");
            zoomListener.scale(scale);
            zoomListener.translate([x, y]);
        }

        // tooltip functions
        function tooltipIn(d, i) {
            if (!settings.enableTooltips) {
                return;
            }
            tooltip.html(settings.getTooltip(d)).style("top", d3.event.pageY - 5 + "px").style("left", d3.event.pageX + 15 + "px");

            tooltipTimer = setTimeout(function () {
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
            return "<h3 class='tip-title'>" + settings.getTooltipTitle(d) + "</h3><p>" + settings.getTooltipText(d) + "</p>";
        }

        function getTooltipTitle(d) {
            return d.name;
        }

        function getTooltipText(d) {
            return d.data.count + " hits";
        }

        var TreeviewNode = function (_univis$Node2) {
            _inherits(TreeviewNode, _univis$Node2);

            function TreeviewNode() {
                var node = arguments.length <= 0 || arguments[0] === undefined ? {} : arguments[0];

                _classCallCheck(this, TreeviewNode);

                var _this3 = _possibleConstructorReturn(this, Object.getPrototypeOf(TreeviewNode).call(this, node));

                _this3.setCount();
                return _this3;
            }

            _createClass(TreeviewNode, [{
                key: "setCount",
                value: function setCount() {
                    if (settings.countAccessor(this)) {
                        this.data.count = settings.countAccessor(this);
                    } else if (this.children) {
                        this.data.count = this.children.reduce(function (sum, c) {
                            return sum + c.data.count;
                        }, 0);
                    } else {
                        this.data.count = 0;
                    }
                }
            }, {
                key: "setSelected",
                value: function setSelected(value) {
                    this.setRecursiveProperty("selected", value);
                }

                // collapse everything

            }, {
                key: "collapseAll",
                value: function collapseAll() {
                    if (this.children && this.children.length === 0) {
                        this.children = null;
                    }
                    if (this.children) {
                        this._children = this.children;
                        this._children.forEach(function (c) {
                            c.collapseAll();
                        });
                        this.children = null;
                    }
                }

                // Collapses a node

            }, {
                key: "collapse",
                value: function collapse() {
                    if (this.children) {
                        this._children = this.children;
                        this.children = null;
                    }
                }
            }, {
                key: "expandAll",
                value: function expandAll() {
                    this.expand(100);
                }

                // Expands a node and its children

            }, {
                key: "expand",
                value: function expand() {
                    var i = arguments.length <= 0 || arguments[0] === undefined ? settings.levelsToExpand : arguments[0];

                    if (i > 0) {
                        if (this._children) {
                            this.children = this._children;
                            this._children = null;
                        }
                        if (this.children) {
                            this.children.forEach(function (c) {
                                c.expand(i - 1);
                            });
                        }
                    }
                }
            }], [{
                key: "new",
                value: function _new() {
                    var node = arguments.length <= 0 || arguments[0] === undefined ? {} : arguments[0];

                    return new TreeviewNode(node);
                }
            }, {
                key: "createNode",
                value: function createNode(node) {
                    return univis.Node.createNode(node, TreeviewNode.new);
                }
            }]);

            return TreeviewNode;
        }(univis.Node);

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
            var $this = $(this);
            var data = $this.data('vis.treeview');
            var options = $.extend({}, $this.data(), (typeof option === "undefined" ? "undefined" : _typeof(option)) === 'object' && option);

            if (!data) {
                $this.data('vis.treeview', data = new TreeView(this, userData, options));
            }
            if (typeof option === 'string') {
                data[option]();
            }
        });
    }

    $.fn.treeview = Plugin;
    $.fn.treeview.Constructor = TreeView;
})();
//# sourceMappingURL=unipept-visualizations.es5.js.map
