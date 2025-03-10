let toasts = 0;
let manager = {
    ready: true,
    jobs: [],
    currentWorkingID: 0,
    interval: null,
    addJob(job) {
        this.ready = false;
        this.jobs.push({ text: job.text, args: job.args });
    },
    removeJob(id) {
        if (this.currentWorkingID === id) {
            this.ready = true;
        }
    },
    workJobsOff() {
        if (this.ready && this.jobs.length > 0) {
            showToast(this.jobs[0].text, this.jobs[0].args);
            this.jobs.splice(0, 1);
        }
    }
};

function showToast(text, args = {}) {
    const selectedToast = toasts;
    if (!manager.ready) {
        manager.addJob({text: text, args: args, workingID: selectedToast});
        return;
    }
    manager.currentWorkingID = selectedToast;

    args.duration = args.duration || 10000; // 3000
    args.background = args.background || "#232323";
    args.color = args.color || "#fff";
    args.borderRadius = args.borderRadius || "0px";

    $("body").append(`
        <div style="background: ${args.background}; color: ${args.color}; z-index: 9999 !important; border-radius: ${args.borderRadius};" data-toast-id="${toasts}" class="toast">
            ${text}
        </div>
    `);

    $(".toast").map((i) => {
        manager.ready = false;
        if (i !== selectedToast) {
            $(".toast").eq(i).animate({
                "margin-top": "+=" + parseInt($(`[data-toast-id="${selectedToast}"]`).height() + (15 * 2) + 15 + 5) + "px"
            }, 300);

            setTimeout(() => {
                manager.removeJob(selectedToast);
            }, 300);
        }else {
            setTimeout(() => {
                $(".toast").eq(i).animate({
                    "margin-top": "25px"
                }, 300);

                setTimeout(() => {
                    manager.removeJob(selectedToast);
                }, 300);
            }, 150);
        }
    });

    setTimeout(() => {
        $(`[data-toast-id="${selectedToast}"]`).animate({
            "margin-right": "-" + parseInt($(`[data-toast-id="${selectedToast}"]`).width() + (15 * 2) + 38) + "px"
        }, 300);

        if (selectedToast !== toasts) {
            $(".toast").map((i) => {
                if (i < selectedToast) {
                    setTimeout(() => {
                        $(".toast").eq(i).animate({
                            "margin-top": "-=" + parseInt($(`[data-toast-id="${selectedToast}"]`).height() + (15 * 2) + 15 + 5) + "px"
                        }, 300);
                    }, 300);
                }
            });
        }

        setTimeout(() => {
            $(`[data-toast-id="${selectedToast}"]`).css("display", "none");
        }, 300);
    }, args.duration);
    toasts++;
}

(() => {
    $("head").append(`
        <style>
            .toast {
                padding: 15px;
                color: #fff;
                position: fixed;
                right: 25px;
                top: 20%;
                margin-top: -100px;
                box-shadow: 0 10px 40px 0 rgba(62,57,107,.07), 0 2px 9px 0 rgba(62,57,107,.12);
                max-width: 50%;
            }
        </style>
    `);

    setInterval(() => {
        manager.workJobsOff();
    }, 250);
})();
