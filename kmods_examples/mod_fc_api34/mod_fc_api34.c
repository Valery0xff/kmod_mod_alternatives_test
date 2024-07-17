
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/types.h>

MODULE_LICENSE("GPL");

uint32_t mod_api3_func(void)
{
	return 0xFC03FC03;
}

uint32_t mod_api4_func(void)
{
	return 0xFC04FC04;
}

EXPORT_SYMBOL(mod_api3_func);
EXPORT_SYMBOL(mod_api4_func);

int mod_fc_api34_init(void)
{
	pr_info("mod_fc_api34: init mod fc api34\n");
	return 0;
}

void mod_fc_api34_exit(void)
{
	pr_info("mod_fc_api34: Goodbye mod fc api34\n");
}

module_init(mod_fc_api34_init);
module_exit(mod_fc_api34_exit);

