
// Quick and simple export target #table_id into a csv
function download_table_as_csv(table_id) {
    // Select rows from table_id
    var rows = document.querySelectorAll('table#' + table_id + ' tr');
    // Construct csv
    var csv = [];
    for (var i = 0; i < rows.length; i++) {
        var row = [], cols = rows[i].querySelectorAll('td, th');
        for (var j = 0; j < cols.length; j++) {
            // Clean innertext to remove multiple spaces and jumpline (break csv)
            var data = cols[j].innerText.replace(/(\r\n|\n|\r)/gm, '').replace(/(\s\s)/gm, ' ')
            // Escape double-quote with double-double-quote (see https://stackoverflow.com/questions/17808511/properly-escape-a-double-quote-in-csv)
            data = data.replace(/"/g, '""');
            // Push escaped string
            row.push('"' + data + '"');
        }
        csv.push(row.join(';'));
    }
    var csv_string = csv.join('\n');
    // Download it
    var filename = 'export_' + table_id + '_' + new Date().toLocaleDateString() + '.csv';
    var link = document.createElement('a');
    link.style.display = 'none';
    link.setAttribute('target', '_blank');
    link.setAttribute('href', 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv_string));
    link.setAttribute('download', filename);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
}
//Code for filtering input
function $x(pNd) {
    var lThis;
    switch (typeof(pNd)) {
        case 'string':
            lThis = document.getElementById(pNd);
            break;
        case 'object':
            lThis = pNd;
            break;
        default:
            return false;
            break;
    }
    return (lThis.nodeType == 1) ? lThis : false;
}

var gRegex = false;
var gHeight = 0;

function $d_Find(pThis, pString, pTags, pClass) {
    if (!pTags) {
        pTags = 'DIV';
    }
    pThis = $x(pThis);
    if (pThis) {
        var d = pThis.getElementsByTagName(pTags);
        pThis.style.display = "none";
        if (!gRegex) {
            gRegex = new RegExp("test");
        }
        var c = 0; // Counter for results
        //var e = 0; //
        var rowCount = 0;
        gRegex.compile(pString, "i");
        for (var i = 0, len = d.length; i < len; i++) {
            if (gRegex.test(d[i].innerHTML)) {
                d[i].style.display = "table-row";
                d[i].style.visiblilty = "visible";
                d[i].style.height = gHeight;
                c++; // 
            } else {
                if (gHeight == 0) gHeight = d[i].style.height;
                d[i].style.height = '0';
                d[i].style.display = "none";
                d[i].style.visiblilty = "hidden";
            }

        }
        pThis.style.display = "block";
    }

    // Code for automatic expanding after results < 30
    // collapse all id's starting with bar (like barenti, barattr)
    if (c <= 30) {
		$(`[id^="bar"]`).collapse('show')
    } else {
		$(`[id^="bar"]`).collapse('hide')
    }

    document.getElementById("count").innerHTML = c;
    return;
}

//placeholder animation
$('input').focus(function() {
    $(this).parents('.form-group').addClass('focused');
});

$('input').blur(function() {
    var inputValue = $(this).val();
    if (inputValue == "") {
        $("#searcher").show();
        $(this).removeClass('filled');
        $(this).parents('.form-group').removeClass('focused');
    } else {
        $(this).addClass('filled');
    }
})

//serchclearer (clears input in searchbar)
$(document).ready(function() {
    $("#first").keyup(function() {
        $("#searchclear").toggle(Boolean($(this).val()));
        $("#searcher").hide();
    });
    $("#searchclear").toggle(Boolean($("#first").val()));
    $("#searchclear").click(function() {
        $("#searcher").show();
        $("#first").val('').focus();
        $(this).hide();
		$d_Find('toc_list','','a')
    });

	//content view for sidebar(desktop) and modal (mobile)
	document.getElementById("btnF").addEventListener("click", function() {

    $("body").css("overflow", "hidden");

    var tree = document.createDocumentFragment();
    var div = document.getElementById("toc_list");

    tree.appendChild(div);

    document.getElementById("modalContent").appendChild(tree);
	});

	document.getElementById("closeM0").addEventListener("click", function() {
    $("body").css("overflow", "auto");

    var tree = document.createDocumentFragment();
    var div = document.getElementById("toc_list");

    tree.appendChild(div);

    document.getElementById("sidebar").appendChild(tree);
	});

	document.getElementById("closeM1").addEventListener("click", function() {
    $("body").css("overflow", "auto");

    var tree = document.createDocumentFragment();
    var div = document.getElementById("toc_list");

    tree.appendChild(div);

    document.getElementById("sidebar").appendChild(tree);
	});


	$('a[href^="#"]').on('click', function(e) {

    window.location.hash = "-------";
	
    e.preventDefault();
	var windowTarget = $(this).attr('target');
    var target = $(this).attr('href');
    var $target = $(target);

	if(windowTarget == '_blank') {
		var url = window.location.pathname + target;
		window.open(url,'_blank');

	} else {
		$('html, body').stop().animate({
        'scrollTop': $target.offset().top
		}, 900, 'swing', function() {
			$tblshow();
			window.location.hash = target;
		});
	} 
	});
    $(window).scroll(function() {
        if ($(this).scrollTop() > 700) {
            $('#btnTop').fadeIn();
        } else {
            $('#btnTop').fadeOut();
        }
    });
    // scroll content to top by clicking on button
    $('#btnTop').click(function() {
        $('body,html').animate({
            scrollTop: 0
        }, 400);
        return false;
    });
	
});

function $tblshow() {
    //locating the clicked table
    var url = window.location.href;

	if(url.indexOf('#') !== -1) {
		var sID = url.substring(url.indexOf('#') + 1);

		//collapsing table
		temp = (sID + ' > div > .collapse');
		
		$('#' + temp).collapse('show');

		//checking if its using the right data
		console.log("URL: " + url + " \n ");
		console.log("ID der Table: " + sID + " \n ");
		console.log("Suchid: " + temp);
	}
}
 