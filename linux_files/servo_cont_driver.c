#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/io.h>
#include <linux/uaccess.h>
#include <linux/of.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("DD");
MODULE_DESCRIPTION("Servo_cont char device driver for control sg-90");

#define DEVICE_NAME "servo_cont"

static dev_t dev_num;
static struct cdev servo_cont_cdev;
static struct class *servo_cont_class;
static struct device *servo_cont_device;
static void __iomem *servo_cont_base;

static int servo_cont_open(struct inode *inode, struct file *file)
{
    return -EPERM;
}

static ssize_t servo_cont_read(struct file *filp, char __user *buf, size_t len, loff_t *offset)
{
    return -EPERM;
}

static ssize_t servo_cont_write(struct file *filp, const char __user *buf, size_t len, loff_t *offset)
{
    return -EPERM;
}

static long servo_cont_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
{
    return -EPERM;
}

static const struct file_operations fops = {
    .owner = THIS_MODULE,
    .open = servo_cont_open,
    .read = servo_cont_read,
    .write = servo_cont_write,
    .unlocked_ioctl = servo_cont_ioctl
};

#define ANGLE_REG_OFFSET 0
#define ENABLE_REG_OFFSET 0x4

static ssize_t angle_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    u32 val = ioread32(servo_cont_base + ANGLE_REG_OFFSET);
    return scnprintf(buf, PAGE_SIZE, "%08x\n", val);
}

static ssize_t angle_store(struct device *dev, struct device_attribute *attr, const char *buf, size_t count)
{
    u32 val;
    if (kstrtou32(buf, 0, &val) || (val > 180))
        return -EINVAL;

    iowrite32(val, servo_cont_base + ANGLE_REG_OFFSET);
    return count;
}

static DEVICE_ATTR_RW(angle);

static ssize_t enable_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    u32 val = ioread32(servo_cont_base + ENABLE_REG_OFFSET);
    return scnprintf(buf, PAGE_SIZE, "%08x\n", val);
}

static ssize_t enable_store(struct device *dev, struct device_attribute *attr, const char *buf, size_t count)
{
    u32 val;
    if (kstrtou32(buf, 0, &val))
        return -EINVAL;

    if (val == 0)
        iowrite32(val, servo_cont_base + ENABLE_REG_OFFSET);
    else if (val == 1)
        iowrite32(0x11111111, servo_cont_base + ENABLE_REG_OFFSET);
    else
        return -EINVAL;

    return count;
}

static DEVICE_ATTR_RW(enable);

static int servo_cont_probe(struct platform_device *pdev)
{
    struct resource *res;
    int ret_val;

    res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
    if (!res) return -ENODEV;

    servo_cont_base = devm_ioremap_resource(&pdev->dev, res);
    if (IS_ERR(servo_cont_base)) return PTR_ERR(servo_cont_base);

    ret_val = alloc_chrdev_region(&dev_num, 0, 1, DEVICE_NAME);
    if (ret_val) return ret_val;

    cdev_init(&servo_cont_cdev, &fops);
    ret_val = cdev_add(&servo_cont_cdev, dev_num, 1);
    if (ret_val) goto err_chrdev;

    servo_cont_class = class_create(THIS_MODULE, DEVICE_NAME);
    if (IS_ERR(servo_cont_class))
    {
        ret_val = PTR_ERR(servo_cont_class);
        goto err_cdev;
    }

    servo_cont_device = device_create(servo_cont_class, NULL, dev_num, NULL, DEVICE_NAME);
    if (IS_ERR(servo_cont_device))
    {
        ret_val = PTR_ERR(servo_cont_device);
        goto err_class;
    }

    ret_val = device_create_file(servo_cont_device, &dev_attr_angle);
    if (ret_val) goto err_device;

    ret_val = device_create_file(servo_cont_device, &dev_attr_enable);
    if (ret_val) goto err_angle;

    dev_info(&pdev->dev, "SERVO_CONT device with sysfs attributes registered\n");
    return 0;

err_angle:
    device_remove_file(servo_cont_device, &dev_attr_angle);
err_device:
    device_destroy(servo_cont_class, dev_num);
err_class:
    class_destroy(servo_cont_class);
err_cdev:
    cdev_del(&servo_cont_cdev);
err_chrdev:
    unregister_chrdev_region(dev_num, 1);
    return ret_val;
}

static int servo_cont_remove(struct platform_device *pdev)
{
    device_remove_file(servo_cont_device, &dev_attr_enable);
    device_remove_file(servo_cont_device, &dev_attr_angle);

    device_destroy(servo_cont_class, dev_num);
    class_destroy(servo_cont_class);
    cdev_del(&servo_cont_cdev);
    unregister_chrdev_region(dev_num, 1);

    dev_info(&pdev->dev, "SERVO_CONT device removed\n");
}

static const struct of_device_id servo_cont_of_match[] = {
    { .compatible = "xlnx,pl-wrapper-1.0" },
    {},
};

MODULE_DEVICE_TABLE(of, servo_cont_of_match);

static struct platform_driver servo_cont_driver = {
    .driver = {
        .name = DEVICE_NAME,
        .of_match_table = servo_cont_of_match,
    },
    .probe = servo_cont_probe,
    .remove = servo_cont_remove,
};

module_platform_driver(servo_cont_driver);


