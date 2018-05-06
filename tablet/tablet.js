(function () {

var stroke = [];
var tablet = d3.select("#tablet");

var canvas = tablet.append("svg")
    .attr("width", 200)
    .attr("height", 200)
    .on("mousedown", mousedown)
    .on("mouseup", mouseup);

function mousedown() {
    var m = d3.mouse(this);
    var p = {x:Math.trunc(m[0]), y:Math.trunc(m[1])};

    // clear canvas when stroke begins
    canvas.selectAll("*").remove();

    // draw first stroke point on canvas
    canvas.append("circle").attr("cx", p.x).attr("cy", p.y);
    stroke.push(p);

    canvas.on("mousemove", mousemove);
}

function mousemove() {
    var m = d3.mouse(this);
    var p = {x:Math.trunc(m[0]), y:Math.trunc(m[1])};

    // draw next stroke point on canvas
    canvas.append("circle").attr("cx", p.x).attr("cy", p.y);
    stroke.push(p);
}

function mouseup() {
    // dump recorded stroke
    output = JSON.stringify(stroke, null, 2);

    dump = d3.select("#dump");
    dump.selectAll("*").remove();
    dump.append("span").attr("class", "dump").text(output);

    // restart for new stroke
    stroke = [];
    canvas.on("mousemove", null);
}

})();

