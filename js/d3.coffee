abs = (n) -> Math.abs(n)
min = (n...) -> Math.min(n...)
max = (n...) -> Math.max(n...)
pow = (n, p) -> Math.pow(n, p)
sqr = (n) -> Math.pow(n, 2)
sqrt = (n) -> Math.sqrt(n)
sum = (o) -> if o.length then o.reduce((a,b) -> a+b) else ""
dist = (a, b) -> sqrt(sum(sqr(ai - (if b then b[i] else 0)) for ai, i in a))
print = (o) -> console.log(o)


s = new tacit.Structure
new s.Beam({x: 0, y: 0}, {x: 1, y: 1})
new s.Beam({x: 1, y: 1}, {x: 2, y: 0})
s.nodeList[i].fixed[dim] = true for i in [0,2] for dim in ["x", "y"]
s.nodeList[1].force.y = -1


showgrad = document.getElementById("grad")
showforce = document.getElementById("force")
move = document.getElementById("move")
showzero = document.getElementById("showzero")

[width, height] = [window.innerWidth, window.innerHeight]
vis = drag_line = null
scale = 1
rescale = ->
    scale = d3.event.scale
    vis.attr("transform",
             "translate(#{d3.event.translate}) scale(#{scale})")
    repositionzoom()
zoomer = d3.behavior.zoom().on("zoom", rescale)

# event handlers
selected_node = selected_link = mousedown_link = mousedown_node = mouseup_node = null
resetMouseVars = -> mousedown_node = mouseup_node = mousedown_link = null

mousedown = -> if not mousedown_node and not mousedown_link # if nothing is selected
    vis.call(d3.behavior.zoom().on("zoom"), rescale)        # allow panning

mousemove = -> if mousedown_node
    if move.checked
        mousedown_node.x =  d3.svg.mouse(this)[0]
        mousedown_node.y =  d3.svg.mouse(this)[1]
        beam.update() for beam in mousedown_node.sourced.concat(mousedown_node.targeted)
        repositionfast()
    else
        drag_line
            .attr("x1", mousedown_node.x).attr("x2", d3.svg.mouse(this)[0])
            .attr("y1", mousedown_node.y).attr("y2", d3.svg.mouse(this)[1])

mouseup = ->
    if mousedown_node
        # hide drag line
        drag_line.attr("class", "drag_line_hidden")
        if not mouseup_node
            # add node
            point = d3.mouse(this)
            node_ = new s.Node({x: point[0], y: point[1]})
            node_.force.y = -1
            # select new node
            selected_node = node_
            selected_link = null
            # add link to mousedown node
            beam_ = new s.Beam(mousedown_node.id, node_.id)
        redraw()
    # clear mouse event vars
    resetMouseVars()

spliceLinksForNode = (node) ->
    toSplice = links.filter((l) -> l.source is node or l.target is node)
    toSplice.map((l) -> links.splice(links.indexOf(l), 1))

keydown = ->
    switch d3.event.keyCode
        when 71  # g
            showgrad.checked = not showgrad.checked
            reposition()
        when 70  # f
            showforce.checked = not showforce.checked
            reposition()
        when 78  # n
            move.checked = not move.checked
        when 66  # b
            showzero.checked = not showzero.checked
            reposition()
        when 8, 46  # backspace, delete
            if selected_node then selected_node.delete()
            else if selected_link then selected_link.delete()
            selected_link = selected_node = null
            redraw()
        else
            null
# init svg
outer = d3.select("#chart")
  .append("svg:svg")
    .attr("width", width)
    .attr("height", height)
    .attr("pointer-events", "all")
vis = outer
  .append('svg:g')
    .attr("transform", "translate(0,#{height}) scale(1,-1)")
  .append('svg:g')
    .call(zoomer)
    .on("dblclick.zoom", null)
  .append('svg:g')
    .on("mousemove", mousemove)
    .on("mousedown", mousedown)
    .on("mouseup", mouseup)
vis.append('svg:rect')
    .attr("x", -width/2)
    .attr("y", -height/2)
    .attr("width", width)
    .attr("height", height)
    .attr("fill", "transparent")
# init nodes,  links, and the line displayed when dragging new nodes
nodes = s.nodeList
links = s.beamList
node = vis.selectAll(".node")
link = vis.selectAll(".link")
force = vis.selectAll(".force")
grad = vis.selectAll(".grad")
drag_line = vis.append("line")
    .attr("class", "drag_line")
    .attr("x1", 0).attr("x2", 0)
    .attr("y1", 0).attr("y2", 0)
# add keyboard callback
d3.select(window).on("keydown", keydown)

prevobj = 0
reposition = ->
    s.solve()
    #print [2 - s.beamList[0].L*s.beamList[1].L/s.nodeList[1].y/s.nodeList[1].y, s.nodeList[1].grad.y]
    drag_line.attr("stroke-width", 10/scale)
             .attr("stroke-dasharray", 10/scale+","+10/scale)
    link.attr("x1", (d) -> d.source.x).attr("x2", (d) -> d.target.x)
        .attr("y1", (d) -> d.source.y).attr("y2", (d) -> d.target.y)
        .attr("stroke-dasharray", (d) -> if d.diameter then null else 10/scale+","+10/scale)
        .classed("compression", (d) -> d.f < 0 and d.diameter)
        .classed("tension", (d) -> d.f > 0 and d.diameter)
        .transition()
          .duration(750)
          .ease("elastic")
            .attr("stroke-width",  (d) -> 10/scale * (d.diameter or 0.5*showzero.checked))
    node.attr("cx", (d) -> d.x)
        .attr("cy", (d) -> d.y)
        .transition()
          .duration(750)
          .ease("elastic")
          .attr("r", (d) -> 18/scale * if d is selected_node then 2 else 1)
    force.attr("stroke-width", (d) -> if dist(f for d, f of d.force) > 50/scale then 10/scale*showforce.checked else 0)
         .attr("x1", (d) -> d.x).attr("x2", (d) -> d.x + d.force.x/4)
         .attr("y1", (d) -> d.y).attr("y2", (d) -> d.y + d.force.y/4)
    grad.attr("x1", (d) -> d.x).attr("x2", (d) -> d.x - 50/scale*d.grad.x*nodes.length/s.lp.obj)
        .attr("y1", (d) -> d.y).attr("y2", (d) -> d.y - 50/scale*d.grad.y*nodes.length/s.lp.obj)
        .attr("stroke-width", (d) -> if 50/scale*dist(l for d, l of d.grad)*nodes.length/s.lp.obj > 0.05 then 10/scale*showgrad.checked else 0)
repositionfast = ->
    s.solve()
    drag_line.attr("stroke-width", 10/scale)
           .attr("stroke-dasharray", 10/scale+","+10/scale)
    link.attr("x1", (d) -> d.source.x).attr("x2", (d) -> d.target.x)
      .attr("y1", (d) -> d.source.y).attr("y2", (d) -> d.target.y)
      .attr("stroke-dasharray", (d) -> if d.diameter then null else 10/scale+","+10/scale)
      .classed("compression", (d) -> d.f < 0 and d.diameter)
      .classed("tension", (d) -> d.f > 0 and d.diameter)
      .attr("stroke-width",  (d) -> 10/scale * (d.diameter or 0.5*showzero.checked))
    node.attr("cx", (d) -> d.x)
      .attr("cy", (d) -> d.y)
      .attr("r", (d) -> 18/scale * if d is selected_node then 2 else 1)
    force.attr("stroke-width", (d) -> if dist(f for d, f of d.force) > 50/scale then 10/scale*showforce.checked else 0)
         .attr("x1", (d) -> d.x).attr("x2", (d) -> d.x + d.force.x/4)
         .attr("y1", (d) -> d.y).attr("y2", (d) -> d.y + d.force.y/4)
    grad.attr("x1", (d) -> d.x).attr("x2", (d) -> d.x - 50/scale*d.grad.x*nodes.length/s.lp.obj)
        .attr("y1", (d) -> d.y).attr("y2", (d) -> d.y - 50/scale*d.grad.y*nodes.length/s.lp.obj)
        .attr("stroke-width", (d) -> if 50/scale*dist(l for d, l of d.grad)*nodes.length/s.lp.obj > 0.05 then 10/scale*showgrad.checked else 0)
repositionzoom = ->
    link.attr("stroke-dasharray", (d) -> if d.diameter then null else 10/scale+","+10/scale)
        .attr("stroke-width",  (d) -> 10/scale * (d.diameter or 0.5*showzero.checked))
    node.attr("r", (d) -> 18/scale * if d is selected_node then 2 else 1)
    force.attr("stroke-width", (d) -> if dist(f for d, f of d.force) > 50/scale then 10/scale*showforce.checked else 0)
    grad.attr("stroke-width", (d) -> if 50/scale*dist(l for d, l of d.grad)*nodes.length/s.lp.obj > 0.05 then 10/scale*showgrad.checked else 0)
@reposition = reposition
@repositionfast = repositionfast
@repositionzoom = repositionzoom

# set inital window
[mins, maxs, means] = [{}, {}, {}]
for d in ["x", "y", "z"]
    list = (n[d] for n in nodes)
    mins[d] = min(list...)
    maxs[d] = max(list...)
    means[d] = sum(list)/nodes.length
scale = 0.5*min(width/(maxs.x-mins.x), height/(maxs.y-mins.y))
translate = [scale*means.x, height/2 - scale*means.y]
zoomer.scale(scale)
zoomer.translate(translate)
vis.attr("transform",
         "translate(#{translate}) scale(#{scale})")

redraw()
setTimeout((->
    s.nodeList[1].move({y: -0.5})
    reposition()), 500)

connectAllNodes = ->
    for ns in nodes
        connected_ids = (b.target.id for b in ns.sourced).concat(b.source.id for b in ns.targeted)
        for nt in s.nodeList when nt.id isnt ns.id
            if connected_ids.indexOf(nt.id) is -1 then new s.Beam(ns.id, nt.id)
    redraw()
@connectAllNodes = connectAllNodes

deleteAllBeams = ->
    while links.length
        links[0].delete()
    redraw()
@deleteAllBeams = deleteAllBeams


`
function redraw() {
  link = link.data(links);
  link.enter().insert("line", ".node")
      .attr("class", "link")
      .on("mousedown",
        function(d) {
          mousedown_link = d;
          if (mousedown_link == selected_link) selected_link = null;
          else selected_link = mousedown_link;
          selected_node = null;
          redraw();
        })
  link.exit().remove();
  link.classed("link_selected", function(d) { return d === selected_link; });

  force = force.data(nodes);
  force.enter().insert("line")
      .attr("class", "force")
      .attr("stroke-width", 0)
      .attr("marker-end", "url(#brtriangle)");
  force.exit().remove();

  grad = grad.data(nodes);
  grad.enter().insert("line")
      .attr("class","grad")
      .attr("stroke-width", 0)
      .attr("marker-end", "url(#ptriangle)");
  grad.exit().remove();

  node =  node.data(nodes);
  node.enter().insert("circle")
      .attr("class", "node")
      .attr("r", 5/scale)
      .on("mousedown",
        function(d) {
          // disable zoom
          vis.call(d3.behavior.zoom().on("zoom"), null);
          mousedown_node = d;
          if (mousedown_node == selected_node) selected_node = null;
          else selected_node = mousedown_node;
          selected_link = null;

          // reposition drag line
          drag_line
              .attr("class", "link")
              .attr("x1", mousedown_node.x)
              .attr("y1", mousedown_node.y)
              .attr("x2", mousedown_node.x)
              .attr("y2", mousedown_node.y);

          redraw();
        })
      .on("mousedrag",
        function(d) {
          // redraw();
        })
      .on("mouseup",
        function(d) {
          if (mousedown_node) {
            mouseup_node = d;
            if (mouseup_node == mousedown_node) { resetMouseVars(); return; }
            // add link
            beam_ = new s.Beam(mousedown_node.id, mouseup_node.id)
            // select new link
            selected_link = null;
            selected_node = mouseup_node;
            // enable zoom
            vis.call(d3.behavior.zoom().on("zoom"), rescale);
            redraw();
          }
        })
    .transition()
      .duration(750)
      .ease("elastic")
      .attr("r", 9/scale);

  node.exit().transition()
      .attr("r", 0)
    .remove();

  node.classed("node_selected", function(d) { return d === selected_node; });

  if (d3.event) d3.event.preventDefault();

  reposition();
}
`
@redraw = redraw
