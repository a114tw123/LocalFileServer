
// 創建 Vue 應用
const app = Vue.createApp({
    data() {
        return {
            count: 0
        };
    },
    methods: {
        increment() {
            this.count++;
        },
        decrement() {
            if (this.count > 0) {
                this.count--;
            }
        }
    }
});

// 挂載應用
app.mount('#app');
